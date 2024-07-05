import Mathlib.Order.Lattice
import Mathlib.Algebra.Order.Group.Defs
import Mathlib.Algebra.Order.Group.Int
import Mathlib.Data.Matroid.Basic
import Matroid.Constructions.CircuitAxioms
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Union
import Mathlib.Order.Antichain
import Mathlib.Data.Finset.Basic
import Matroid.Rank

open Finset

variable {α β : Type*}

-- Should this be predicate or class?
def Submodular [Lattice α] [LinearOrderedAddCommMonoid β] (f : α → β) :=
  ∀ X Y, f (X ⊓ Y) + f (X ⊔ Y) ≤ f X + f Y

open Matroid

-- prop 11.1.1
@[simps!] def ofSubmodular [DecidableEq α] {f : Finset α → ℤ} (h_sub : Submodular f)
    (h_mono : Monotone f) : Matroid α := by
  set Circuit := fun C ↦ C ∈ minimals (· ⊆ ·) {C | C.Nonempty ∧ f C < C.card}
  have circuit_antichain := @minimals_antichain (Finset α) (· ⊆ ·) {C | C.Nonempty ∧ f C < C.card}
    Finset.instIsAntisymmSubset
  have circuit_f_lt_card : ∀ ⦃C⦄, Circuit C → f C < C.card := fun C hC ↦ hC.1.2
  have indep_f_ge_card : ∀ ⦃I C⦄, Circuit C → I ⊂ C → I.Nonempty → I.card ≤ f I := by
    intro I C hC hI hI_nonempty
    by_contra! h_lt
    exact not_ssubset_of_subset (hC.2 ⟨hI_nonempty, h_lt⟩ hI.subset) hI
  exact FinsetCircuitMatroid.matroid <| FinsetCircuitMatroid.mk
    (E := Set.univ)
    (Circuit := Circuit)
    (empty_not_circuit := fun h ↦ not_nonempty_empty (mem_minimals_iff.mp h).left.left)
    (circuit_antichain := circuit_antichain)
    (circuit_elimination := by
      intro C₁ C₂ e hC₁ hC₂ h_ne he
      obtain ⟨heC₁, heC₂⟩ := mem_inter.mp he
      set D := (C₁ ∪ C₂).erase e
      suffices h : D ∈ {C | C.Nonempty ∧ f C < C.card} by
        obtain ⟨C, hC, hC_mem, hC_min⟩ := exists_minimal_satisfying_subset
          (fun C ↦ C.Nonempty ∧ f C < C.card) subset_rfl h
        use C;
        refine ⟨⟨hC_mem, hC_min⟩, hC⟩
      refine ⟨?_, ?_⟩
      · contrapose! h_ne; simp only [not_nonempty_iff_eq_empty] at h_ne
        rw [erase_eq_empty_of_mem (inter_subset_union he)] at h_ne
        obtain ⟨rfl, rfl⟩ := singleton_subset_inter_and_union_subset_singleton
          (singleton_subset_iff.mpr he) (by rw [h_ne];)
        rfl
      obtain ⟨hC₁_ne, hC₂_ne⟩ := FinsetCircuitMatroid.intro_elimination_nontrivial
        circuit_antichain hC₁ hC₂ h_ne he
      have hfCi : ∀ ⦃C⦄, Circuit C → e ∈ C → C.Nontrivial → f C = C.card - 1 := by
        intro C hC he hC_non
        refine le_antisymm ?_ ?_
        · rw [Int.le_sub_one_iff]; exact circuit_f_lt_card hC
        calc (C.card : ℤ) - 1
          _ = ↑(C.erase e).card := by
            rw [← Nat.cast_one, ← Nat.cast_sub, Nat.cast_inj, card_erase_of_mem he]
            exact (one_lt_card_iff_nontrivial.mpr hC_non).le
          _ ≤ f (C.erase e) :=
            indep_f_ge_card hC (erase_ssubset he) <| (erase_nonempty he).mpr hC_non
          _ ≤ f C := by
            apply h_mono; simp only [le_eq_subset]; exact erase_subset e C
      calc f D
        _ ≤ f (C₁ ∪ C₂) := h_mono (erase_subset e <| C₁ ∪ C₂)
        _ ≤ f C₁ + f C₂ - f (C₁ ∩ C₂) := by
          linarith [@inf_eq_inter α _ ▸ @sup_eq_union α _ ▸ h_sub C₁ C₂]
        _ = C₁.card - 1 + C₂.card - 1 - f (C₁ ∩ C₂) := by
          rw [hfCi hC₁ heC₁ hC₁_ne, hfCi hC₂ heC₂ hC₂_ne]; ring
        _ ≤ C₁.card - 1 + C₂.card - 1 - (C₁ ∩ C₂).card := by
          suffices (C₁ ∩ C₂).card ≤ f (C₁ ∩ C₂) by linarith
          have h_nonempty : (C₁ ∩ C₂).Nonempty := by use e
          have h_ssubset : (C₁ ∩ C₂) ⊂ C₁ :=
            inter_ssubset_of_not_subset_left (circuit_antichain hC₁ hC₂ h_ne)
          exact indep_f_ge_card hC₁ h_ssubset h_nonempty
        _ = C₁.card + C₂.card - (C₁ ∩ C₂).card - 2 := by ring
        _ = (C₁ ∪ C₂).card - 2 := by rw [coe_card_inter]; ring
        _ = D.card - 1 := by
          have : e ∈ C₁ ∪ C₂ := mem_union_left C₂ heC₁
          rw [card_erase_of_mem <| this, Nat.cast_sub <| (by simp only [one_le_card]; use e)]
          ring
        _ < D.card := sub_one_lt _
    )
    (circuit_subset_ground := by simp)
    (Indep := fun I ↦ ∀ ⦃C⦄, C ⊆ I → ¬Circuit C)
    (indep_iff := by simp)

@[simp] theorem circuit_ofSubmodular_iff [DecidableEq α] {f : Finset α → ℤ}
    (h_sub : Submodular f) (h_mono : Monotone f) (C : Finset α) :
    (ofSubmodular h_sub h_mono).Circuit C ↔
    C ∈ minimals (· ⊆ ·) {C | C.Nonempty ∧ f C < C.card} := by
  unfold ofSubmodular
  simp only [FinsetCircuitMatroid.matroid_circuit_iff]

-- corollary 11.1.2
@[simp] theorem indep_ofSubmodular_iff [DecidableEq α] {f : Finset α → ℤ}
    (h_sub : Submodular f) (h_mono : Monotone f) (I : Finset α) :
    (ofSubmodular h_sub h_mono).Indep I ↔ ∀ I' ⊆ I, I'.Nonempty → I'.card ≤ f I' := by
  simp only [ofSubmodular_Indep, IndepMatroid.ofFinset_indep]
  refine ⟨fun h ↦ ?_, fun h ↦ ?_⟩
  · intro I' hI' hI'_non
    contrapose! h
    obtain ⟨C, hC_subset, hC_min⟩ := exists_minimal_satisfying_subset
      (· ∈ {C | C.Nonempty ∧ f C < ↑C.card}) subset_rfl ⟨hI'_non, h⟩
    use C;
    refine ⟨hC_subset.trans hI', hC_min⟩
  intro I' h' hI'
  obtain ⟨h_nonempty, h_con⟩ := hI'.1
  linarith [h I' h' h_nonempty]

-- definition at bottom of page 406
structure PolymatroidFn [Lattice α] [Bot α] [LinearOrderedAddCommMonoid β] (f : α → β) :=
  (submodular : Submodular f)
  (mono : Monotone f)
  (zero_at_bot : f ⊥ = 0)

variable {f : Finset α → ℤ}

@[simps!] def ofPolymatroidFn [DecidableEq α] (h : PolymatroidFn f) :=
  ofSubmodular h.submodular h.mono

@[simp] theorem indep_ofPolymatroidFn_iff [DecidableEq α] (hf : PolymatroidFn f) (I : Finset α) :
    (ofPolymatroidFn hf).Indep I ↔ ∀ I' ⊆ I, I'.Nonempty → I'.card ≤ f I' := by
  simp only [ofPolymatroidFn, indep_ofSubmodular_iff]

theorem ofPolymatroidFn_nonempty_indep_le [DecidableEq α] {hf : PolymatroidFn f} {I : Finset α}
    (h' : I.Nonempty) (h : (ofPolymatroidFn hf).Indep I) : I.card ≤ f I := by
  exact (indep_ofPolymatroidFn_iff hf I).mp h I subset_rfl h'

theorem polymatroid_rank_eq_on_indep [DecidableEq α] {hf : PolymatroidFn f} {X : Finset α}
    (hX_indep : (ofPolymatroidFn hf).Indep X) :
    (∃ Y ⊆ X, (ofPolymatroidFn hf).r X = f Y + (X \ Y).card ∧
     ∀ Y' ⊆ X, f Y + (X \ Y).card ≤ f Y' + (X \ Y').card) := by
  set M := ofPolymatroidFn hf
  unfold r
  rw [hX_indep.er, Set.encard_coe_eq_coe_finsetCard, ENat.toNat_coe]
  use ∅
  simp only [empty_subset, sdiff_empty, self_eq_add_left, true_and]
  rw [← bot_eq_empty, hf.zero_at_bot]
  simp only [zero_add, true_and]
  intro Y hY
  rw [Finset.cast_card_sdiff hY]
  change (Y : Set α) ⊆ X at hY
  have hY_indep := hX_indep.subset hY
  simp only [M, indep_ofPolymatroidFn_iff] at hY_indep
  by_cases hY_nonempty : Y.Nonempty
  · specialize hY_indep Y subset_rfl hY_nonempty
    linarith
  simp only [not_nonempty_iff_eq_empty] at hY_nonempty
  rw [hY_nonempty, card_empty, ← bot_eq_empty, hf.zero_at_bot]
  simp only [Nat.cast_zero, sub_zero, zero_add, le_refl]

-- proposition 11.1.7
-- need to refactor
theorem polymatroid_rank_eq [DecidableEq α] (hf : PolymatroidFn f) (X : Finset α) :
    (∃ Y ⊆ X, f Y + (X \ Y).card ≤ (ofPolymatroidFn hf).r X) ∧
    (∀ Y ⊆ X, (ofPolymatroidFn hf).r X ≤ f Y + (X \ Y).card) := by
  set M := ofPolymatroidFn hf
  obtain ⟨B, hB⟩ := M.exists_basis X (by simp only [ofPolymatroidFn_E, Set.subset_univ, M])
  have hB_finite : B.Finite := Set.Finite.subset X.finite_toSet hB.subset
  have hB_fintype : Fintype ↑B := by exact hB_finite.fintype
  rw [← Set.coe_toFinset B] at hB
  refine ⟨?_, ?_⟩; swap
  · intro Y _
    rw [← hB.r]
    simp only [M] at hB
    obtain ⟨W, _, hW, h⟩ := polymatroid_rank_eq_on_indep hB.indep
    rw [hW]
    calc f W + ↑(B.toFinset \ W).card
      _ ≤ f (Y ∩ B.toFinset) + ↑(B.toFinset \ (Y ∩ B.toFinset)).card :=
        h (Y ∩ B.toFinset) inter_subset_right
      _ ≤ f Y + ↑(B.toFinset \ (Y ∩ B.toFinset)).card := by
        linarith [hf.mono <| @inter_subset_left α _ Y B.toFinset]
      _ ≤ f Y + ↑(X \ Y).card := by
        simp only [sdiff_inter_self_right, add_le_add_iff_left, Nat.cast_le]
        refine card_le_card ?_
        refine sdiff_subset_sdiff hB.subset subset_rfl
  have h_choice : ∀ e : ↑(X \ B.toFinset),
      ∃ I ⊆ B.toFinset, M.Indep I ∧ f (insert ↑e I) < (insert ↑e I).card := by
    intro e
    have h_ins : M.Dep (insert e.val B) := by
      have : ↑e ∈ X.toSet \ ↑B.toFinset := by
        rw [← coe_sdiff]
        exact e.2
      replace this := hB.insert_dep this
      simpa only [Set.coe_toFinset] using this
    obtain ⟨C, hC_subset, hC⟩ := h_ins.exists_circuit_subset
    have : Fintype ↑C := by
      have : C ⊆ ↑(insert ↑e B.toFinset) := by
        rwa [coe_insert, Set.coe_toFinset]
      exact ((insert ↑e B.toFinset).finite_toSet.subset this).fintype
    set I := C.toFinset.erase e
    have hI : I ⊆ B.toFinset := by
      intro x hx
      obtain ⟨hxe, hx⟩ := mem_erase.mp hx
      simp only [Set.mem_toFinset] at hx ⊢
      obtain ⟨h, h⟩ := Set.mem_insert_iff.mp <| hC_subset hx
      · contradiction
      assumption
    use I
    refine ⟨hI, hB.indep.subset hI, ?_⟩
    by_cases he : ↑e ∈ C.toFinset; swap
    · exfalso
      simp only [Set.mem_toFinset] at he
      have := ((Set.subset_insert_iff_of_not_mem he).mp hC_subset)
      rw [← Set.coe_toFinset B] at this
      exact hC.dep.1 <| hB.indep.subset this
    rw [insert_erase he]
    simp only [M, ofPolymatroidFn] at hC
    rw [← Set.coe_toFinset C, circuit_ofSubmodular_iff hf.submodular hf.mono] at hC
    exact hC.1.2
  choose I h_subset h_indep h_lt using h_choice
  set Ie := fun e : ↑(X \ B.toFinset) ↦ insert ↑e (I e)
  have h_induc : ∀ Y : Finset ↑(X \ B.toFinset), Y.Nonempty →
    f (Finset.biUnion Y Ie) ≤ (Finset.biUnion Y I).card := by
    intro Y hY_nonempty
    induction' hY_nonempty using Finset.Nonempty.strong_induction
    case h₀ a =>
      have ha : ↑a ∈ X \ B.toFinset := coe_mem a
      replace ha : ↑a ∉ I a := by
        specialize h_subset a
        contrapose! ha
        exact not_mem_sdiff_of_mem_right <| h_subset ha
      simp only [singleton_biUnion, Ie]
      rw [← Int.lt_add_one_iff, ← Nat.cast_one, ← Nat.cast_add, ← card_insert_of_not_mem ha]
      exact h_lt a
    case h₁ Y hY IH =>
      obtain ⟨T, a, ha, b, hb, hab, h⟩ := Nontrivial.exists_cons_eq hY
      set Y' := (cons b T hb) with hY'
      have hIH := IH Y' (nonempty_cons hb) (by rw [← h]; exact ssubset_cons _)
      rw [← h, cons_eq_insert, ← hY', biUnion_insert, biUnion_insert]
      calc f (Ie a ∪ Y'.biUnion Ie)
        _ ≤ f (Ie a) + f (Y'.biUnion Ie) - f (Ie a ∩ Y'.biUnion Ie) := by
          have := hf.submodular (Ie a) (Y'.biUnion Ie)
          simp only [inf_eq_inter, sup_eq_union] at this
          linarith [this]
        _ ≤ f (Ie a) + f (Y'.biUnion Ie) - (Ie a ∩ Y'.biUnion Ie).card := by
          have : Ie a ∩ Y'.biUnion Ie ⊆ I a := by
            intro x hx
            obtain (rfl | h) := mem_insert.mp <| mem_of_mem_inter_left hx; swap
            · assumption
            exfalso
            replace hx := mem_of_mem_inter_right hx
            simp only [mem_biUnion, Subtype.exists] at hx
            obtain ⟨e, he, heY', h_con⟩ := hx
            have : a ∉ Y' := (Iff.not mem_cons).mpr (not_or_intro hab ha)
            obtain (rfl | h) := mem_insert.mp h_con
            · simp only [Subtype.coe_eta] at heY'
              exact this heY'
            replace this := h_subset ⟨e, he⟩ <| h
            exact (mem_sdiff.mp a.2).right this
          obtain (h_empty | h_nonempty) := eq_empty_or_nonempty (Ie a ∩ Y'.biUnion Ie)
          · rw [h_empty, card_empty, ← bot_eq_empty, hf.zero_at_bot, Nat.cast_zero]
          linarith [ofPolymatroidFn_nonempty_indep_le h_nonempty <|
            (h_indep a).subset <| coe_subset.mpr this]
        _ ≤ f (Ie a) + f (Y'.biUnion Ie) - (I a ∩ Y'.biUnion I).card := by
          have : I a ∩ Y'.biUnion I ⊆ (Ie a ∩ Y'.biUnion Ie) := by
            refine inter_subset_inter ?_ ?_
            · exact subset_insert (↑a) (I a)
            refine biUnion_mono fun a _ ↦ subset_insert (↑a) (I a)
          linarith [card_mono this]
        _ ≤ f (Ie a) + (Y'.biUnion I).card - (I a ∩ Y'.biUnion I).card := by
          linarith [hIH]
        _ ≤ (I a).card + (Y'.biUnion I).card - (I a ∩ Y'.biUnion I).card := by
          have : {a} ⊂ Y := by
            refine Finset.ssubset_iff_subset_ne.mpr ⟨?_, ?_⟩
            · simp only [singleton_subset_iff, ← h]
              exact mem_cons_self a (cons b T hb)
            exact Ne.symm (Nontrivial.ne_singleton hY)
          specialize IH {a} (singleton_nonempty a) this
          simp only [singleton_biUnion] at IH
          linarith [IH]
        _ = (I a ∪ Y'.biUnion I).card := by exact Eq.symm cast_card_union
  use univ.biUnion Ie
  refine ⟨?_, ?_⟩
  · intro x hx
    simp only [mem_biUnion, mem_univ, true_and] at hx
    obtain ⟨e, he⟩ := hx
    exact insert_subset (sdiff_subset <| coe_mem e) ((h_subset e).trans hB.subset) <| he
  rw [← hB.r]
  unfold r
  rw [hB.indep.er, Set.encard_coe_eq_coe_finsetCard, ENat.toNat_coe]
  have h_eq : X \ univ.biUnion Ie = B.toFinset \ univ.biUnion I := by
    ext x; refine ⟨fun h ↦ ?_, fun h ↦ ?_⟩
    <;> refine mem_sdiff.mpr ⟨?_, ?_⟩
    · have :  X \ B.toFinset ⊆ univ.biUnion Ie := by
        intro a ha
        simp only [univ_eq_attach, mem_biUnion, mem_attach, true_and, Subtype.exists]
        use a, ha
        exact mem_insert_self a (I ⟨a, ha⟩)
      replace h := sdiff_subset_sdiff (subset_refl X) this <| h
      simp only [sdiff_sdiff_right_self, inf_eq_inter] at h
      exact mem_of_mem_inter_right h
    -- thanks aesop
    · simp_all only [Set.coe_toFinset, Set.subset_toFinset, Subtype.forall, mem_sdiff,
      Set.mem_toFinset, ofPolymatroidFn_Indep, IndepMatroid.ofFinset_indep, univ_eq_attach,
        mem_biUnion, mem_attach, mem_insert, true_and, Subtype.exists, not_exists, not_or,
        not_false_eq_true, and_self, exists_false, M, Ie]
    · exact hB.subset (mem_sdiff.mp h).left
    -- thanks aesop
    simp_all only [Set.coe_toFinset, Set.subset_toFinset, Subtype.forall, mem_sdiff,
      Set.mem_toFinset, ofPolymatroidFn_Indep, IndepMatroid.ofFinset_indep, univ_eq_attach,
      mem_biUnion, mem_attach, true_and, Subtype.exists, not_exists, mem_insert, not_false_eq_true,
      and_self, or_false, exists_prop, exists_eq_right', not_true_eq_false, and_false, M, Ie]
  rw [h_eq, cast_card_sdiff, add_sub]
  · obtain (rfl | hXB) := eq_or_ne X B.toFinset
    · simp only [sdiff_self, bot_eq_empty, not_mem_empty, isEmpty_subtype, not_false_eq_true,
      implies_true, univ_eq_empty, biUnion_empty, Set.toFinset_card, card_empty, Nat.cast_zero,
      sub_zero, add_le_iff_nonpos_left, ge_iff_le]
      rw [← bot_eq_empty, hf.zero_at_bot]
    have h_nonempty : (@univ ↑(X \ B.toFinset) _).Nonempty := by
      have := hXB.symm.ssubset_of_subset <| Finset.coe_subset.mp hB.subset
      obtain ⟨x, hx⟩ := Finset.exists_of_ssubset this
      simp only [univ_eq_attach, attach_nonempty_iff]
      use x
      exact mem_sdiff.mpr hx
    linarith [h_induc univ h_nonempty]
  intro x hx
  simp only [mem_biUnion, mem_univ, true_and] at hx
  obtain ⟨e, he⟩ := hx
  exact h_subset e he
