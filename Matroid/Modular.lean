import Matroid.Flat
import Matroid.Simple

open Set

namespace Matroid

variable {M : Matroid α} {B : Set α} {Xs Ys : Set (Set α)}

section ModularBase

/-- A base `B` is a modular base for a set family if its intersection with every set in the family
  is a basis for that set. -/
@[pp_dot] def ModularBase (M : Matroid α) (B : Set α) (Xs : Set (Set α)) :=
  M.Base B ∧ ∀ ⦃X⦄, X ∈ Xs → M.Basis (X ∩ B) X

theorem ModularBase.base (h : M.ModularBase B Xs) : M.Base B := h.1

theorem ModularBase.indep (h : M.ModularBase B Xs) : M.Indep B := h.1.indep

theorem ModularBase.basis_inter (h : M.ModularBase B Xs) (hX : X ∈ Xs) : M.Basis (X ∩ B) X :=
  h.2 hX

theorem ModularBase.subset (h : M.ModularBase B Xs) (hYs : Ys ⊆ Xs) : M.ModularBase B Ys :=
  ⟨h.1, fun _ hY ↦ h.2 (hYs hY)⟩

@[simp] theorem modularBase_pair_iff {B X Y : Set α} :
    M.ModularBase B {X,Y} ↔ M.Base B ∧ M.Basis (X ∩ B) X ∧ M.Basis (Y ∩ B) Y := by
  simp [ModularBase]

theorem ModularBase.basis_sInter (h : M.ModularBase B Xs) (hne : Xs.Nonempty) :
    M.Basis ((⋂₀ Xs) ∩ B) (⋂₀ Xs) :=
  h.1.indep.interBasis_sInter hne h.2

theorem ModularBase.basis_sInter_subset (h : M.ModularBase B Xs) (hYs : Ys ⊆ Xs)
    (hne : Ys.Nonempty) : M.Basis ((⋂₀ Ys) ∩ B) (⋂₀ Ys) :=
  (h.subset hYs).basis_sInter hne

@[aesop unsafe 5% (rule_sets [Matroid])]
theorem ModularBase.sInter_subset_ground (h : M.ModularBase B Xs) (hne : Xs.Nonempty) :
    ⋂₀ Xs ⊆ M.E :=
  (h.basis_sInter hne).subset_ground

@[aesop unsafe 5% (rule_sets [Matroid])]
theorem ModularBase.mem_subset_ground (h : M.ModularBase B Xs) (hX : X ∈ Xs) : X ⊆ M.E :=
  (h.basis_inter hX).subset_ground

@[aesop unsafe 5% (rule_sets [Matroid])]
theorem ModularBase.sUnion_subset_ground (h : M.ModularBase B Xs) : ⋃₀ Xs ⊆ M.E := by
  rw [sUnion_subset_iff]; exact fun X hX ↦ h.mem_subset_ground hX

theorem exists_modularBase_of_sUnion_indep (h : M.Indep (⋃₀ Xs)) : ∃ B, M.ModularBase B Xs := by
  obtain ⟨B, hB, huB⟩ := h.exists_base_superset
  refine ⟨B, hB, fun {X} hX ↦ ?_⟩
  have hXB : X ⊆ B := (subset_sUnion_of_mem hX).trans huB
  rw [inter_eq_self_of_subset_left hXB]
  exact (hB.indep.subset hXB).basis_self

theorem ModularBase.basis_sUnion (h : M.ModularBase B Xs) : M.Basis (⋃₀ Xs ∩ B) (⋃₀ Xs) := by
  refine' Indep.basis_of_subset_of_subset_cl (h.indep.inter_left _) (inter_subset_left _ _)
    (sUnion_subset (fun X hX ↦ _))
  have hb := h.basis_inter hX
  rw [←cl_subset_cl_iff_subset_cl, ←hb.cl_eq_cl]
  exact M.cl_subset_cl (inter_subset_inter_left _ (subset_sUnion_of_mem hX))

theorem ModularBase.subset_cl_inter_of_mem (h : M.ModularBase B Xs) (hX : X ∈ Xs) :
    X ⊆ M.cl (X ∩ B) :=
  (h.basis_inter hX).subset_cl

theorem ModularBase.sInter_subset_cl_inter_of_mem (h : M.ModularBase B Xs) (hne : Xs.Nonempty) :
    ⋂₀ Xs ⊆ M.cl (⋂₀ Xs ∩ B) :=
  (h.basis_sInter hne).subset_cl

theorem Base.modularBase_of_forall_subset_cl (hB : M.Base B) (h : ∀ ⦃X⦄, X ∈ Xs → X ⊆ M.cl (X ∩ B)) :
    M.ModularBase B Xs :=
  ⟨hB, fun _ hX ↦ hB.indep.inter_basis_cl_iff_subset_cl_inter.2 (h hX)⟩

theorem ModularBase.basis_sUnion_of_subset (h : M.ModularBase B Xs) (hYs : Ys ⊆ Xs) :
    M.Basis (⋃₀ Ys ∩ B) (⋃₀ Ys) :=
  (h.subset hYs).basis_sUnion

theorem ModularBase.iInter_cl_eq_cl_sInter (hB : M.ModularBase B Xs) (hne : Xs.Nonempty) :
    (⋂ X ∈ Xs, M.cl X) = M.cl (⋂₀ Xs) := by
  have := hne.coe_sort
  have eq1 : (⋂ X ∈ Xs, M.cl X) = (⋂ X ∈ Xs, M.cl (X ∩ B))
  · convert rfl using 4 with X hX
    rw [(hB.basis_inter hX).cl_eq_cl]
  rw [eq1, ←biInter_image, ←hB.indep.cl_sInter_eq_biInter_cl_of_forall_subset,
    ←(hB.basis_sInter hne).cl_eq_cl, eq_comm, sInter_eq_iInter, iInter_inter]
  · convert rfl; simp
  · apply hne.image
  simp

end ModularBase
section ModularFamily

def ModularFamily (M : Matroid α) (Xs : Set (Set α)) := ∃ B, M.ModularBase B Xs

theorem Indep.modularFamily (hI : M.Indep I) (hXs : ∀ ⦃X⦄, X ∈ Xs → M.Basis (X ∩ I) X) :
    M.ModularFamily Xs := by
  simp_rw [hI.inter_basis_cl_iff_subset_cl_inter] at hXs
  obtain ⟨B, hB, hIB⟩ := hI
  refine ⟨B, hB, ?_⟩
  simp_rw [hB.indep.inter_basis_cl_iff_subset_cl_inter]
  exact fun {X} hX ↦ (hXs hX).trans (M.cl_subset_cl (inter_subset_inter_right _ hIB))

theorem ModularFamily.subset_ground_of_mem (h : M.ModularFamily Xs) (hX : X ∈ Xs) : X ⊆ M.E :=
  let ⟨_, hI⟩ := h
  (hI.basis_inter hX).subset_ground

theorem ModularFamily.iInter_cl_eq_cl_sInter (hXs : M.ModularFamily Xs) (hne : Xs.Nonempty) :
    (⋂ X ∈ Xs, M.cl X) = M.cl (⋂₀ Xs) :=
  let ⟨_, hB⟩ := hXs
  hB.iInter_cl_eq_cl_sInter hne

theorem Indep.modularFamily_of_subsets (hI : M.Indep I) {Js : Set (Set α)} (hJs : ⋃₀ Js ⊆ I) :
    M.ModularFamily Js := by
  refine hI.modularFamily (fun {J} hJ ↦ ?_)
  have hJI : J ⊆ I := (subset_sUnion_of_mem hJ).trans hJs
  rw [inter_eq_self_of_subset_left hJI]
  exact (hI.subset hJI).basis_self

def ModularPair (M : Matroid α) (X Y : Set α) := M.ModularFamily {X,Y}

theorem ModularPair.symm (h : M.ModularPair X Y) : M.ModularPair Y X := by
  rwa [ModularPair, pair_comm, ← ModularPair]

theorem ModularPair.comm : M.ModularPair X Y ↔ M.ModularPair Y X :=
  ⟨ModularPair.symm, ModularPair.symm⟩

@[aesop unsafe 5% (rule_sets [Matroid])]
theorem ModularPair.subset_ground_left (h : M.ModularPair X Y) : X ⊆ M.E :=
  ModularFamily.subset_ground_of_mem h (by simp)

@[aesop unsafe 5% (rule_sets [Matroid])]
theorem ModularPair.subset_ground_right (h : M.ModularPair X Y) : Y ⊆ M.E :=
  ModularFamily.subset_ground_of_mem h (by simp)

@[simp] theorem modularPair_iff {M : Matroid α} {X Y : Set α} :
    M.ModularPair X Y ↔ ∃ I, M.Indep I ∧ M.Basis (X ∩ I) X ∧ M.Basis (Y ∩ I) Y := by
  simp only [ModularPair, ModularFamily, mem_singleton_iff, modularBase_pair_iff]
  refine ⟨fun ⟨B, hB, hB'⟩ ↦ ⟨B, hB.indep, hB'⟩,
    fun ⟨I, ⟨B, hB, hIB⟩, hIX, hIY⟩ ↦ ⟨B, hB, ?_, ?_⟩⟩
  · rwa [← hIX.eq_of_subset_indep (hB.indep.inter_left X) (inter_subset_inter_right _ hIB)
      (inter_subset_left _ _)]
  rwa [← hIY.eq_of_subset_indep (hB.indep.inter_left Y) (inter_subset_inter_right _ hIB)
    (inter_subset_left _ _)]

theorem modularPair_iff_exists_subsets_cl_inter :
    M.ModularPair X Y ↔ ∃ I, M.Indep I ∧ X ⊆ M.cl (X ∩ I) ∧ Y ⊆ M.cl (Y ∩ I)  := by
  rw [modularPair_iff]
  refine ⟨fun ⟨I,hI,h⟩ ↦ ⟨I,hI,?_⟩, fun ⟨I,hI,h⟩ ↦ ⟨I,hI,?_⟩⟩
  · rwa [← hI.inter_basis_cl_iff_subset_cl_inter, ← hI.inter_basis_cl_iff_subset_cl_inter]
  rwa [hI.inter_basis_cl_iff_subset_cl_inter, hI.inter_basis_cl_iff_subset_cl_inter]

theorem ModularPair.exists_subsets_cl_inter (h : M.ModularPair X Y) :
    ∃ I, M.Indep I ∧ X ⊆ M.cl (X ∩ I) ∧ Y ⊆ M.cl (Y ∩ I) :=
  modularPair_iff_exists_subsets_cl_inter.1 h

theorem modularPair_iff_exists_basis_basis :
    M.ModularPair X Y ↔ ∃ I J, M.Basis I X ∧ M.Basis J Y ∧ M.Indep (I ∪ J) := by
  rw [modularPair_iff]
  refine ⟨fun ⟨I,hI,hIX,hIY⟩ ↦ ⟨_, _, hIX, hIY, hI.subset (by simp)⟩,
    fun ⟨I,J,hI,hJ,hi⟩ ↦ ⟨_,hi, ?_⟩⟩
  simp_rw [hi.inter_basis_cl_iff_subset_cl_inter]
  use hI.subset_cl.trans (M.cl_subset_cl (subset_inter hI.subset (subset_union_left _ _)))
  exact hJ.subset_cl.trans (M.cl_subset_cl (subset_inter hJ.subset (subset_union_right _ _)))

theorem ModularPair.inter_cl_eq (h : M.ModularPair X Y) : M.cl (X ∩ Y) = M.cl X ∩ M.cl Y := by
  convert (ModularFamily.iInter_cl_eq_cl_sInter h (by simp)).symm <;> simp

theorem modularPair_of_subset (hXY : X ⊆ Y) (hY : Y ⊆ M.E) : M.ModularPair X Y := by
  obtain ⟨I,J, hI, hJ, hIJ⟩ := M.exists_basis_subset_basis hXY
  refine modularPair_iff.2 ⟨J, hJ.indep, ?_, by rwa [inter_eq_self_of_subset_right hJ.subset]⟩
  rwa [← hI.eq_of_subset_indep (hJ.indep.inter_left X) (subset_inter hI.subset hIJ)
    (inter_subset_left _ _)]

theorem Indep.modularPair_of_union (hi : M.Indep (I ∪ J)) : M.ModularPair I J :=
  hi.modularFamily_of_subsets (Js := {I,J}) (by simp)

theorem ModularPair.of_subset_cl_left (h : M.ModularPair X Y) (hXX' : X ⊆ X') (hX' : X' ⊆ M.cl X) :
    M.ModularPair X' Y := by
  rw [modularPair_iff_exists_subsets_cl_inter] at h ⊢
  obtain ⟨I, hI, hX, hY⟩ := h
  refine ⟨I, hI, hX'.trans ((M.cl_subset_cl_of_subset_cl hX).trans (M.cl_subset_cl ?_)), hY⟩
  exact inter_subset_inter_left _ hXX'

theorem ModularPair.of_subset_cl_right (h : M.ModularPair X Y) (hYY' : Y ⊆ Y') (hY' : Y' ⊆ M.cl Y) :
    M.ModularPair X Y' :=
  (h.symm.of_subset_cl_left hYY' hY').symm

theorem ModularPair.of_subset_cl_subset_cl (h : M.ModularPair X Y) (hXX' : X ⊆ X')
    (hX' : X' ⊆ M.cl X) (hYY' : Y ⊆ Y') (hY' : Y' ⊆ M.cl Y) : M.ModularPair X' Y' :=
  (h.of_subset_cl_left hXX' hX').of_subset_cl_right hYY' hY'

theorem ModularPair.of_basis_left (h : M.ModularPair I Y) (hIX : M.Basis I X) :
    M.ModularPair X Y :=
  h.of_subset_cl_left hIX.subset hIX.subset_cl

theorem ModularPair.of_basis_right (h : M.ModularPair X J) (hJY : M.Basis J Y) :
    M.ModularPair X Y :=
  h.of_subset_cl_right hJY.subset hJY.subset_cl

theorem ModularPair.of_basis_of_basis (h : M.ModularPair I J) (hIX : M.Basis I X)
    (hJY : M.Basis J Y) : M.ModularPair X Y :=
  (h.of_basis_left hIX).of_basis_right hJY

theorem ModularPair.cl_left (h : M.ModularPair X Y) : M.ModularPair (M.cl X) Y :=
  h.of_subset_cl_left (M.subset_cl X) Subset.rfl

theorem ModularPair.cl_right (h : M.ModularPair X Y) : M.ModularPair X (M.cl Y) :=
  h.symm.cl_left.symm

theorem ModularPair.cl_cl (h : M.ModularPair X Y) : M.ModularPair (M.cl X) (M.cl Y) :=
  h.cl_left.cl_right

theorem modularPair_singleton (he : e ∈ M.E) (hX : X ⊆ M.E) (heX : e ∉ M.cl X) :
    M.ModularPair {e} X := by
  obtain ⟨I, hI⟩ := M.exists_basis X
  have hi : M.Indep (insert e I)
  · rw [hI.indep.insert_indep_iff, hI.cl_eq_cl]
    exact Or.inl ⟨he, heX⟩
  have hI' := hI.insert_basis_insert hi
  rw [← singleton_union] at hI'
  exact hI'.indep.modularPair_of_union.of_basis_right hI

end ModularFamily

section ModularSet

/-- A `ModularSet` is a set that is a modular pair with every flat. -/
def ModularSet (M : Matroid α) (X : Set α) := ∀ ⦃F⦄, M.Flat F → M.ModularPair X F

@[simp] theorem modularSet_def {M : Matroid α} {X : Set α} :
    M.ModularSet X ↔ ∀ ⦃F⦄, M.Flat F → M.ModularPair X F := Iff.rfl

@[aesop unsafe 5% (rule_sets [Matroid])]
theorem ModularSet.subset_ground (h : M.ModularSet X) : X ⊆ M.E :=
  (h (M.cl_flat ∅)).subset_ground_left

@[simp] theorem modularSet_iff {M : Matroid α} {X : Set α} :
    M.ModularSet X ↔ ∀ ⦃F⦄, M.Flat F → ∃ I, M.Indep I ∧ M.Basis (X ∩ I) X ∧ M.Basis (F ∩ I) F := by
  simp [ModularSet, modularPair_iff]

theorem modularSet_iff_cl {M : Matroid α} {X : Set α} :
    M.ModularSet X ↔ ∀ ⦃F⦄, M.Flat F → ∃ I, M.Indep I ∧ X ⊆ M.cl (X ∩ I) ∧ F ⊆ M.cl (F ∩ I) := by
  rw [modularSet_iff]
  refine ⟨fun h F hF ↦ ?_, fun h F hF ↦ ?_⟩
  · obtain ⟨I, hI, hI'⟩ := h hF
    refine ⟨I, hI, ?_⟩
    rwa [← hI.inter_basis_cl_iff_subset_cl_inter, ← hI.inter_basis_cl_iff_subset_cl_inter]
  obtain ⟨I, hI, hI'⟩ := h hF
  refine ⟨I, hI, ?_⟩
  rwa [hI.inter_basis_cl_iff_subset_cl_inter, hI.inter_basis_cl_iff_subset_cl_inter]

theorem modularSet_ground (M : Matroid α) : M.ModularSet M.E :=
  modularSet_def.2 (fun _ hF ↦ (modularPair_of_subset hF.subset_ground Subset.rfl).symm)

theorem modularSet_empty (M : Matroid α) : M.ModularSet ∅ :=
  modularSet_def.2 (fun _ hF ↦ (modularPair_of_subset (empty_subset _) hF.subset_ground))

theorem modularSet.cl (h : M.ModularSet X) : M.ModularSet (M.cl X) :=
  fun _ hF ↦ (h hF).cl_left

theorem modularSet_singleton (M : Matroid α) (he : e ∈ M.E) : M.ModularSet {e} := by
  refine modularSet_def.2 fun F hF ↦ ?_
  by_cases heF : {e} ⊆ F
  · apply modularPair_of_subset heF hF.subset_ground
  rw [singleton_subset_iff, ← hF.cl] at heF
  exact modularPair_singleton he hF.subset_ground heF

/-- Every modular set in a simple matroid is a flat. -/
theorem ModularSet.Flat [Simple M] (hF : M.ModularSet F) : M.Flat F := by
  by_contra h
  obtain ⟨e, heF, he⟩ := exists_mem_cl_not_mem_of_not_flat h
  rw [modularSet_iff] at hF
  obtain ⟨I, hI, hIF, hIe⟩ := hF (M.cl_flat {e})
  have heM := M.cl_subset_ground F heF
  have heI : e ∈ I
  · rw [hI.inter_basis_cl_iff_subset_cl_inter, cl_singleton_eq,
      cl_eq_self_of_subset_singleton heM (inter_subset_left _ _)] at hIe
    simpa using hIe
  apply hI.not_mem_cl_diff_of_mem heI
  apply mem_of_mem_of_subset <| M.cl_subset_cl_of_subset_cl hIF.subset_cl heF
  apply M.cl_subset_cl
  rw [subset_diff, and_iff_right (inter_subset_right _ _), disjoint_singleton_right]
  exact fun he' ↦ he <| (inter_subset_left _ _) he'

end ModularSet

section Skew

def SkewFamily (M : Matroid α) (Xs : Set (Set α)) :=
  M.ModularFamily Xs ∧ ∀ ⦃X Y⦄, X ∈ Xs → Y ∈ Xs → X ≠ Y → X ∩ Y ⊆ M.cl ∅

end Skew


end Matroid
