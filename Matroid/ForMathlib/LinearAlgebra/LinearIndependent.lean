import Mathlib.LinearAlgebra.FiniteDimensional
import Mathlib.LinearAlgebra.Dual
import Matroid.ForMathlib.Other

variable {α ι W W' R : Type _} [AddCommGroup W] [Field R] [Module R W] [AddCommGroup W'] [Module R W']

open Set Submodule BigOperators


theorem Fintype.subtype_notLinearIndependent_iff [Fintype ι] [CommSemiring R]
  [AddCommMonoid M] [Module R M] {s : Set ι} {v : ι → M} :
    ¬ LinearIndependent R (s.restrict v) ↔ ∃ c : ι → R, ∑ i, c i • v i = 0 ∧ (∃ i ∈ s, c i ≠ 0)
      ∧ ∀ i, i ∉ s → c i = 0 := by
  classical
  have _ := s.toFinite.fintype
  rw [Fintype.not_linearIndependent_iff]
  refine ⟨fun ⟨c', hc', i₀, hi₀⟩ ↦ ?_, fun ⟨c, hc0, ⟨i₀, hi₀, hne⟩, hi⟩ ↦ ?_⟩
  · set f := fun i ↦ if hi : i ∈ s then c' ⟨i,hi⟩ • (v i) else 0
    refine ⟨fun i ↦ if hi : i ∈ s then c' ⟨i,hi⟩ else 0, ?_, ⟨i₀, i₀.prop, by simpa⟩,
      fun i hi ↦ by simp [hi]⟩
    rw [←hc']
    convert Finset.sum_congr_set s f (fun i ↦ (c' i) • v i) (fun _ h ↦ by simp [h])
      (fun _ h ↦ by simp [h])
    · simp only; split_ifs; rfl; exact zero_smul _ _
  refine ⟨fun i ↦ c i, ?_, ⟨⟨i₀, hi₀⟩, hne⟩⟩
  rw [←hc0, eq_comm]
  convert Finset.sum_congr_set s (fun i ↦ (c i) • (v i)) (fun i ↦ (c i) • v i)
    (fun x _ ↦ rfl) (fun _ hx ↦ by simp [hi _ hx])

theorem linearIndependent_of_finite' {R M ι : Type _} [DivisionRing R] [AddCommGroup M]
    [Module R M] (f : ι → M) (h : ∀ (t : Set ι), t.Finite → LinearIndependent R (t.restrict f)) :
    LinearIndependent R f := by
  have hinj : f.Injective
  · intro x y hxy
    have hli := (h {x,y} (toFinite _))
    have h : (⟨x, by simp⟩ : ({x,y} : Set ι)) = ⟨y, by simp⟩
    · rw [←hli.injective.eq_iff]; simpa
    simpa using h
  rw [←linearIndependent_subtype_range hinj]
  refine linearIndependent_of_finite _ fun t ht htfin ↦ ?_
  obtain ⟨t, rfl⟩ := subset_range_iff_exists_image_eq.1 ht
  exact (linearIndependent_image (injOn_of_injective hinj t)).1 <|
    h t (htfin.of_finite_image (injOn_of_injective hinj t))

theorem linearIndependent_iUnion_of_directed' {R M ι η : Type _} [DivisionRing R] [AddCommGroup M]
    [Module R M] (f : ι → M) (s : η → Set ι) (hs : Directed (· ⊆ ·) s)
    (h : ∀ j, LinearIndependent R ((s j).restrict f)) :
    LinearIndependent R ((⋃ j, s j).restrict f) := by
  obtain (h_empt | hne) := isEmpty_or_nonempty η
  · rw [iUnion_of_empty s]
    apply linearIndependent_empty_type
  apply linearIndependent_of_finite' _ (fun t ht ↦ ?_)
  obtain ⟨I,hIfin, hI⟩ :=
    finite_subset_iUnion (ht.image Subtype.val) (Subtype.coe_image_subset (⋃ j, s j) t)
  obtain ⟨z, hz⟩ := hs.finset_le hIfin.toFinset
  have hss : Subtype.val '' t ⊆ s z
  · refine hI.trans (iUnion_subset fun i j h ↦ ?_)
    simp only [mem_iUnion, exists_prop] at h
    exact hz i (by simpa using h.1) h.2
  set emb : t → s z := (inclusion hss) ∘ (imageFactorization Subtype.val t)
  refine (h z).comp emb <| Function.Injective.comp (inclusion_injective hss) ?_
  exact InjOn.imageFactorization_injective (Subtype.val_injective.injOn _)

theorem linearIndependent_sUnion_of_directed' {R M ι : Type _} [DivisionRing R] [AddCommGroup M]
    [Module R M] (f : ι → M) (s : Set (Set ι)) (hs : DirectedOn (· ⊆ ·) s)
    (h : ∀ c ∈ s, LinearIndependent R (c.restrict f)) :
    LinearIndependent R ((⋃₀ s).restrict f) := by
  rw [sUnion_eq_iUnion]
  apply linearIndependent_iUnion_of_directed' _ _ _ (by aesop)
  rintro x y
  specialize hs x x.prop y y.prop
  aesop

theorem LinearIndependent.finite_index {K : Type u} {V : Type v} [DivisionRing K] [AddCommGroup V]
  [Module K V] [FiniteDimensional K V] {f : α → V} (h : LinearIndependent K f) : Finite α :=
  Cardinal.lt_aleph0_iff_finite.1 <| FiniteDimensional.lt_aleph0_of_linearIndependent h

noncomputable def LinearIndependent.fintype_index {K : Type u} {V : Type v} [DivisionRing K]
  [AddCommGroup V] [Module K V] [FiniteDimensional K V] {f : α → V} (h : LinearIndependent K f) :
    Fintype α :=
  have _ := h.finite_index
  Fintype.ofFinite α

theorem linearIndependent_subtype_congr {R M : Type _} [Semiring R] [AddCommMonoid M] [Module R M]
  {s s' : Set M} (h_eq : s = s') :
    LinearIndependent R ((↑) : s → M) ↔ LinearIndependent R ((↑) : s' → M) := by
  subst h_eq; rfl

variable {K V ι : Type _} [DivisionRing K] [AddCommGroup V] [Module K V] {f : ι → V}
  {s₀ s t : Set ι}

theorem exists_linearIndependent_extension' (hli : LinearIndependent K (s₀.restrict f))
    (hs₀t : s₀ ⊆ t) : ∃ (s : Set ι), s₀ ⊆ s ∧ s ⊆ t ∧ f '' t ⊆ span K (f '' s) ∧
      LinearIndependent K (s.restrict f) := by
  have hzorn := zorn_subset_nonempty {r | s₀ ⊆ r ∧ r ⊆ t ∧ LinearIndependent K (r.restrict f)}
    ?_ s₀ ⟨Subset.rfl, hs₀t, hli⟩
  · obtain ⟨m, ⟨hs₀m, hmt, hli⟩, -, hmax⟩ := hzorn
    refine ⟨m, hs₀m, hmt, ?_, hli⟩
    rintro _ ⟨x, hx, rfl⟩
    by_contra hxm
    have hxm' : x ∉ m := fun hxm' ↦ hxm <| subset_span <| mem_image_of_mem _ hxm'
    have hli' := (linearIndependent_insert' hxm').2 ⟨hli, hxm⟩
    rw [←hmax _ ⟨hs₀m.trans <| subset_insert _ _, insert_subset hx hmt, hli'⟩ (subset_insert _ _)]
      at hxm'
    exact hxm' <| mem_insert _ _
  rintro c hcss hchain ⟨r, hr⟩
  refine ⟨⋃₀ c, ⟨(hcss hr).1.trans <| subset_sUnion_of_mem hr,
    sUnion_subset fun t' ht'c ↦ (hcss ht'c).2.1,?_⟩, fun _ ↦ subset_sUnion_of_mem⟩
  apply linearIndependent_sUnion_of_directed' _ _ (IsChain.directedOn hchain)
    (fun s hs ↦ (hcss hs).2.2)

noncomputable def LinearIndependent.extend' (h : LinearIndependent K (s.restrict f)) (hst : s ⊆ t) :
    Set ι :=
  Classical.choose <| exists_linearIndependent_extension' h hst

theorem LinearIndependent.extend'_subset (h : LinearIndependent K (s.restrict f)) (hst : s ⊆ t) :
    h.extend' hst ⊆ t :=
  (Classical.choose_spec (exists_linearIndependent_extension' h hst)).2.1

theorem LinearIndependent.subset_extend' (h : LinearIndependent K (s.restrict f)) (hst : s ⊆ t) :
    s ⊆ h.extend' hst :=
  (Classical.choose_spec (exists_linearIndependent_extension' h hst)).1

theorem LinearIndependent.subset_span_extend' (h : LinearIndependent K (s.restrict f))
    (hst : s ⊆ t) : f '' t ⊆ span K (f '' (h.extend' hst)) :=
  (Classical.choose_spec (exists_linearIndependent_extension' h hst)).2.2.1

theorem LinearIndependent.linearIndependent_extend' (h : LinearIndependent K (s.restrict f))
    (hst : s ⊆ t) : LinearIndependent K ((h.extend' hst).restrict f) :=
  (Classical.choose_spec (exists_linearIndependent_extension' h hst)).2.2.2
