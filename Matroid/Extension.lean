import Matroid.Simple
import Matroid.Closure
import Matroid.Minor.Basic
import Matroid.Constructions.ImagePreimage
open Set
namespace Matroid

variable {M : Matroid α}

/-- Replace the elements of `S` with parallel copies of `e`. -/
def ParallelExt (M : Matroid α) (e : α) (S : Set α) [DecidablePred (· ∈ S)] : Matroid α :=
    M.preimage (fun x ↦ if (x ∈ S) then e else x)

theorem Indep.parallel_substitute (hI : M.Indep I) (h_para : M.Parallel e f) (hI_e : e ∈ I):
    M.Indep (insert f (I \ {e})) := by
  by_cases e_ne_f : e = f
  · rwa [←e_ne_f, insert_diff_singleton, insert_eq_of_mem hI_e]
  · rw [indep_iff_forall_subset_not_circuit']
    refine' ⟨fun C C_sub C_circ ↦ _, _⟩
    · have e_notin_C : e ∉ C := fun e_in_C ↦ (mem_of_mem_insert_of_ne (C_sub e_in_C) e_ne_f).2 rfl
      have C_ne_ef : C ≠ {e, f}
      · intro h_f
        rw [h_f] at e_notin_C
        exact e_notin_C (mem_insert e _)
      obtain ⟨C', C'_circ, C'_sub⟩ :=
        C_circ.elimination ((parallel_iff_circuit e_ne_f).1 h_para) C_ne_ef f
      have C'_sub_I : C' ⊆ I
      intro c c_sub_C'
      obtain ⟨(c_sub_C | c_sub_ef), (c_ne_f : c ≠ f)⟩ := C'_sub c_sub_C'
      · exact (mem_of_mem_insert_of_ne (C_sub c_sub_C) c_ne_f).1
      · have c_eq_e : c = e
        · apply eq_of_not_mem_of_mem_insert c_sub_ef _
          rwa [mem_singleton_iff]
        rwa [c_eq_e]
      exact (hI.subset C'_sub_I).not_dep C'_circ.1
    · rintro i (i_eq_f | i_sub_I)
      · rw [i_eq_f]
        exact h_para.mem_ground_right
      · exact hI.subset_ground i_sub_I.1

theorem insert_diff_insert_diff {B : Set α} (e_in_B : e ∈ B) (f_notin_B : f ∉ B):
    insert e (insert f (B \ {e}) \ {f}) = B := by simp [e_in_B, f_notin_B]

theorem Equiv.image_invol [DecidableEq α] {e f : α} :
    Function.Involutive (Set.image (Equiv.swap e f)) := by
  have inv : Function.Involutive (Equiv.swap e f) := fun x ↦ Equiv.swap_apply_self _ _ _
  intro X
  rw [←Set.image_comp _ _, Function.Involutive.comp_self inv, image_id]

theorem Equiv.swap_mem_image_iff [DecidableEq α] {e f : α} :
    x ∈ (Equiv.swap e f) '' S ↔ (Equiv.swap e f) x ∈ S := by
  refine' ⟨fun h ↦ _, fun h ↦ _⟩
  · obtain ⟨x', x'_mem, hx'⟩ := h
    rwa [←hx', Equiv.swap_apply_self]
  · refine' ⟨(Equiv.swap e f) x, h, _⟩
    rw [Equiv.swap_apply_self]

theorem Equiv.swap_image_eq_self_both_mem [DecidableEq α] (S : Set α) (he : e ∈ S) (hf : f ∈ S) :
    (Equiv.swap e f) '' S = S := by
  ext x
  rw [Equiv.swap_mem_image_iff]
  by_cases x_eq_e : x = e
  · rw [x_eq_e, Equiv.swap_apply_left]
    exact ⟨fun _ ↦ he, fun _ ↦ hf⟩
  · by_cases x_eq_f : x = f
    · rw [x_eq_f, Equiv.swap_apply_right]
      exact ⟨fun _ ↦ hf, fun _ ↦ he⟩
    · rw [Equiv.swap_apply_of_ne_of_ne x_eq_e x_eq_f]

theorem Equiv.swap_image_eq_self_not_mem [DecidableEq α] {S : Set α} (he : e ∉ S) (hf : f ∉ S) :
    (Equiv.swap e f) '' S = S := by
  ext x
  rw [Equiv.swap_mem_image_iff]
  refine' ⟨fun h ↦ _, fun h ↦ _⟩
  · rwa [←(@Equiv.swap_apply_self _ _ e f x),
      Equiv.swap_apply_of_ne_of_ne (ne_of_mem_of_not_mem h he)
  (ne_of_mem_of_not_mem h hf)]
  rwa [Equiv.swap_apply_of_ne_of_ne (ne_of_mem_of_not_mem h he) (ne_of_mem_of_not_mem h hf)]

theorem Equiv.swap_image_eq_self_left [DecidableEq α] {S : Set α} (he : e ∈ S) (hf : f ∉ S) :
    (Equiv.swap e f) '' S = insert f (S \ {e}) := by
  ext x
  rw [Equiv.swap_mem_image_iff]
  by_cases x_eq_f : x = f
  · refine' ⟨fun _ ↦ _, fun _ ↦ _⟩
    · rw [x_eq_f]
      exact mem_insert f _
    · rwa [x_eq_f, Equiv.swap_apply_right]
  · refine' ⟨fun h ↦ _, fun h ↦ _⟩
    · have x_ne_e : x ≠ e
      · intro x'_eq_e
        rw [x'_eq_e, Equiv.swap_apply_left] at h
        apply hf h
      rw [Equiv.swap_apply_of_ne_of_ne x_ne_e x_eq_f] at h
      exact mem_insert_of_mem f (mem_diff_of_mem h x_ne_e)
    · obtain ⟨x_in_S, (x_ne_e : x ≠ e)⟩ := mem_of_mem_insert_of_ne h x_eq_f
      rwa [Equiv.swap_apply_of_ne_of_ne x_ne_e x_eq_f]

theorem Equiv.swap_image_eq_self [DecidableEq α] {S : Set (Set α)}
    (h_B : ∀ B, B ∈ S ↔ (Equiv.swap e f) '' B ∈ S) : S = Set.image (Equiv.swap e f) '' S := by
  ext B
  refine' ⟨fun B_S ↦ _, fun ⟨B', B'_mem, hB'⟩ ↦ _⟩
  · refine' ⟨(Equiv.swap e f) '' B, (h_B B).1 B_S, _⟩
    rw [Equiv.image_invol.eq_iff]
  rw [←hB']
  exact (h_B B').1 B'_mem


def parallel_swap [DecidableEq α] {M : Matroid α} {e f : α} (h_para : M.Parallel e f) :
    Iso M M where
  toLocalEquiv := (Equiv.swap e f).toLocalEquiv.restr M.E
  source_eq' := by
    simp
  target_eq' := by
    simp only [LocalEquiv.restr_target, Equiv.toLocalEquiv_target,
      Equiv.toLocalEquiv_symm_apply, Equiv.symm_swap, univ_inter]
    rw [preimage_eq_iff_eq_image, Equiv.swap_image_eq_self_both_mem M.E
      h_para.mem_ground_left h_para.mem_ground_right]
    exact Equiv.bijective _
  setOf_base_eq' := by
    apply Equiv.swap_image_eq_self _
    intro B
    by_cases e_in_B : e ∈ B
    by_cases f_in_B : f ∈ B
    · rw [Equiv.swap_image_eq_self_both_mem B e_in_B f_in_B]
    · rw [Equiv.swap_image_eq_self_left e_in_B f_in_B]
      refine' ⟨fun (B_Base : M.Base B) ↦ _, fun (B'_Base : M.Base _) ↦ _⟩
      · exact Base.exchange_base_of_indep B_Base f_in_B
          ((B_Base.indep).parallel_substitute h_para e_in_B)
      · rw [←insert_diff_insert_diff e_in_B f_in_B]
        apply Base.exchange_base_of_indep B'_Base ?_
          ((B'_Base.indep).parallel_substitute h_para.symm (mem_insert f _))
        exact fun e_in_B' ↦ (mem_of_mem_insert_of_ne e_in_B'
          (ne_of_mem_of_not_mem e_in_B f_in_B)).2 rfl
    by_cases f_in_B : f ∈ B
    · rw [Equiv.swap_comm, Equiv.swap_image_eq_self_left f_in_B e_in_B]
      refine' ⟨fun (B_Base : M.Base B) ↦ _, fun (B'_Base : M.Base _) ↦ _⟩
      · exact Base.exchange_base_of_indep B_Base e_in_B
          ((B_Base.indep).parallel_substitute h_para.symm f_in_B)
      · rw [←insert_diff_insert_diff f_in_B e_in_B]
        apply Base.exchange_base_of_indep B'_Base ?_
          ((B'_Base.indep).parallel_substitute h_para (mem_insert e _))
        exact fun f_in_B' ↦
          (mem_of_mem_insert_of_ne f_in_B' (ne_of_mem_of_not_mem f_in_B e_in_B)).2 rfl
    rw [Equiv.swap_image_eq_self_not_mem e_in_B f_in_B]


@[simp] theorem parallel_swap_apply [DecidableEq α] (h_para : M.Parallel e f) :
    (parallel_swap h_para).toLocalEquiv = (Equiv.swap e f).toLocalEquiv.restr M.E := rfl
    -- (parallel_swap h_para).toLocalEquiv = (fun x ↦ if (x = e) then f else (if (x = f) then e else x)) := sorry

theorem filter_preimage_eq {e f : α} [DecidableEq α] {S : Set α} (e_S : e ∈ S) (f_S : f ∈ S)
    (h_ne : e ≠ f) : (fun x ↦ if (x = e) then f else x) ⁻¹' (S \ {e})= S := by
  apply subset_antisymm
  · intro x x_mem
    rw [mem_preimage] at x_mem
    by_cases x_eq_e : x = e
    · rwa [x_eq_e]
    · rw [if_neg x_eq_e] at x_mem
      exact x_mem.1
  · intro x x_mem
    rw [mem_preimage]
    by_cases x_eq_e : x = e
    · rw [if_pos x_eq_e]
      exact ⟨f_S, h_ne.symm⟩
    · rw [if_neg x_eq_e]
      exact ⟨x_mem, x_eq_e⟩

open Classical
theorem eq_parallelExt_del {M : Matroid α} {e f : α} (h_para : M.Parallel e f) (h_ne : e ≠ f):
    M = ParallelExt (M ⟍ f) e {f} := by
  rw [ParallelExt, eq_iff_indep_iff_indep_forall, preimage_ground_eq]
  refine' ⟨_, fun I I_ground ↦ ⟨fun I_Ind ↦ _, _⟩⟩
  · simp only [mem_singleton_iff, delete_elem, delete_ground]
    rw [filter_preimage_eq (h_para.mem_ground_right) (h_para.mem_ground_left) h_ne.symm]
  · rw [preimage_indep_iff]
    simp only [delete_elem, mem_singleton_iff, delete_indep_iff, disjoint_singleton_right,
      mem_image, not_exists, not_and, delete_ground, union_singleton, mem_diff, not_true, and_false,
      insert_diff_singleton]
    constructor
    · constructor
      · by_cases f_in_I : f ∈ I
        · have image_eq : (fun a ↦ if a = f then e else a) '' I = insert e (I \ {f})
          · apply subset_antisymm
            · rintro i ⟨a, a_I, h_a₁⟩
              dsimp at h_a₁
              by_cases a_eq_f : a = f
              · rw [if_pos a_eq_f] at h_a₁
                rw [←h_a₁]
                exact mem_insert _ _
              · rw [if_neg a_eq_f] at h_a₁
                rw [←h_a₁]
                exact mem_insert_of_mem _ (mem_diff_singleton.2 ⟨a_I, a_eq_f⟩)
            · rintro i (i_eq_e | ⟨i_in_I, (i_ne_f : i ≠ f)⟩)
              · refine' ⟨f, f_in_I, _⟩
                rw [i_eq_e]
                exact if_pos rfl
              · refine ⟨i, i_in_I, if_neg i_ne_f⟩
          rw [image_eq]
          apply I_Ind.parallel_substitute h_para.symm f_in_I
        · have image_eq : (fun a ↦ if a = f then e else a) '' I = I
          · apply subset_antisymm
            · rintro i ⟨a, a_I, h_a₁⟩
              dsimp at h_a₁
              rw [if_neg (ne_of_mem_of_not_mem a_I f_in_I)] at h_a₁
              rwa [←h_a₁]
            · rintro i i_in_I
              refine' ⟨i, i_in_I, if_neg (ne_of_mem_of_not_mem i_in_I f_in_I)⟩
          rwa [image_eq]
      · intro x _
        by_cases x_eq_f : x = f
        · rwa [if_pos x_eq_f]
        · rwa [if_neg x_eq_f]

    --refine' ⟨_, subset_trans I_ground (subset_insert f M.E)⟩
    rintro a a_I b b_I f_ab
    dsimp at f_ab
    by_cases b_eq_f : b = f
    · rw [if_pos b_eq_f, ite_eq_left_iff] at f_ab
      by_cases a_eq_f : a = f
      · rwa [b_eq_f]
      · have ef_sub_I : {e, f} ⊆ I
        · rintro i (i_eq_e | (i_eq_f : i = f))
          · rwa [i_eq_e, ←(f_ab a_eq_f)]
          · rwa [i_eq_f, ←b_eq_f]
        exfalso
        apply I_Ind.not_dep _
        rw [dep_iff_superset_circuit]
        exact ⟨{e, f}, ef_sub_I, (parallel_iff_circuit h_ne).1 h_para⟩
    · rw [if_neg b_eq_f] at f_ab
      by_cases a_eq_f : a = f
      · rw [if_pos a_eq_f] at f_ab
        have ef_sub_I : {e, f} ⊆ I
        · rintro i (i_eq_e | (i_eq_f : i = f))
          · rwa [i_eq_e, f_ab]
          · rwa [i_eq_f, ←a_eq_f]
        exfalso
        apply I_Ind.not_dep _
        rw [dep_iff_superset_circuit]
        exact ⟨{e, f}, ef_sub_I, (parallel_iff_circuit h_ne).1 h_para⟩
      · rwa [if_neg a_eq_f] at f_ab
  -- part 2
  rw [preimage_indep_iff]

  rintro ⟨(I_image_Indep : (M ⟍ f).Indep ((fun x ↦ if x = f then e else x) '' I)), h_inj⟩
  by_cases f_in_I : f ∈ I
  · have image_eq : (fun a ↦ if a = f then e else a) '' I = insert e (I \ {f})
    · apply subset_antisymm
      · rintro i ⟨a, a_I, h_a₁⟩
        dsimp at h_a₁
        by_cases a_eq_f : a = f
        · rw [if_pos a_eq_f] at h_a₁
          rw [←h_a₁]
          exact mem_insert _ _
        · rw [if_neg a_eq_f] at h_a₁
          rw [←h_a₁]
          exact mem_insert_of_mem _ (mem_diff_singleton.2 ⟨a_I, a_eq_f⟩)
      · rintro i (i_eq_e | ⟨i_in_I, (i_ne_f : i ≠ f)⟩)
        · refine' ⟨f, f_in_I, _⟩
          rw [i_eq_e]
          exact if_pos rfl
        · refine ⟨i, i_in_I, if_neg i_ne_f⟩
    rw [image_eq] at I_image_Indep
    have:= I_image_Indep.of_delete.parallel_substitute h_para (mem_insert e _)
    have e_notin_I : e ∉ I
    · intro e_in_I
      apply h_ne (h_inj e_in_I f_in_I _)
      dsimp
      simp
    rwa [←insert_diff_insert_diff f_in_I e_notin_I]
  · have image_eq : (fun a ↦ if a = f then e else a) '' I = I
    · apply subset_antisymm
      · rintro i ⟨a, a_I, h_a₁⟩
        dsimp at h_a₁
        rw [if_neg (ne_of_mem_of_not_mem a_I f_in_I)] at h_a₁
        rwa [←h_a₁]
      · intro i i_in_I
        refine' ⟨i, i_in_I, _⟩
        exact if_neg (ne_of_mem_of_not_mem i_in_I f_in_I)
    rw [image_eq] at I_image_Indep
    exact I_image_Indep.of_delete
--another definition of "modularity" exists in the repo- is such that a base is modular over a set
--subsets if for any subset of that set, the intersection of the base with the intersection of
--that subset is a base for the intersection of the subset - cant find what exactly this means wrt
--modular pairs

open Set

@[pp_dot] def Modular_pair (M : Matroid α) (X Y : Set α) : Prop :=
    ∃ B, M.Modular {X, Y} B

@[pp_dot] def Modular_set (M : Matroid α) (X : Set α) : Prop :=
    ∀ Y, M.Flat Y → M.Modular_pair X Y

@[pp_dot] def Modular_matroid (M : Matroid α) : Prop :=
    ∀ X, M.Flat X → M.Modular_set X

def Modular_flat (M : Matroid α) (X : Set α) : Prop :=
    ∀ Y, M.Flat Y → Modular_pair M X Y

def Modular_cut (M : Matroid α) (C : Set (Set α)) : Prop :=
    (∀ F ∈ C, M.Flat F) ∧ (∀ F F', F ∈ C → F ⊆ F' → M.Flat F' → F' ∈ C) ∧
    (∀ F₁ F₂, F₁ ∈ C → F₂ ∈ C → M.Modular_pair F₁ F₂ → F₁ ∩ F₂ ∈ C)

theorem subset_pair_none {A B : Set α} {X : Set (Set α)} (Xne : X.Nonempty) (hX : X ⊆ {A, B}) :
    X = {A} ∨ X = {B} ∨ X = {A, B} := by
  by_cases A_in_X : A ∈ X
  · by_cases B_in_X : B ∈ X
    · exact (Or.inr (Or.inr (subset_antisymm hX (insert_subset A_in_X
       (singleton_subset_iff.2 B_in_X)))))
    · rw [pair_comm] at hX
      exact Or.inl (subset_antisymm ((subset_insert_iff_of_not_mem B_in_X).1 hX)
       (singleton_subset_iff.2 A_in_X))
  · by_cases B_in_X : B ∈ X
    · exact Or.inr (Or.inl (subset_antisymm ((subset_insert_iff_of_not_mem A_in_X).1 hX)
     (singleton_subset_iff.2 B_in_X)))
    · rw [Xne.subset_singleton_iff.1 ((subset_insert_iff_of_not_mem A_in_X).1 hX)] at B_in_X
      exact absurd (Set.mem_singleton B) B_in_X

theorem union_insert_eq {A : Set α} {b c : α} :
    (insert b A) ∪ (insert c A) = insert c (insert b A) := by
  rw [insert_eq, insert_eq, ←union_union_distrib_right, @union_comm _ {b} _,
    union_assoc, ←insert_eq, ←insert_eq]

theorem inter_insert_eq {A : Set α} {b c : α} (hne : b ≠ c):
    (insert b A) ∩ (insert c A) = A := by
  rw [insert_eq, insert_eq, ←union_distrib_right, Disjoint.inter_eq _, empty_union]
  rwa [disjoint_singleton]




@[simp] theorem Modular_ground (M : Matroid α) : M.Modular_set M.E := by
  intro Y Y_flat
  obtain ⟨B, h_B⟩ := M.exists_basis Y
  obtain ⟨B', B'_base, B_sub_B'⟩ := h_B.indep
  refine' ⟨B', B'_base, _⟩
  have B'_inter : B' ∩ Y = B
  · apply subset_antisymm _ _
    · rintro x ⟨x_B, x_Y⟩
      by_contra h_f
      apply ((B'_base.indep).subset (insert_subset x_B B_sub_B')).not_dep
      exact h_B.insert_dep ⟨x_Y, h_f⟩
    · intro x x_B
      exact ⟨B_sub_B' x_B, h_B.subset x_B⟩
  rintro X X_sub X_ne
  obtain (X_eq_E | X_eq_Y | X_eq_pair) := subset_pair_none X_ne X_sub
  · rwa [X_eq_E, sInter_singleton, inter_eq_self_of_subset_right B'_base.subset_ground,
     basis_ground_iff]
  · rwa [X_eq_Y, sInter_singleton, inter_comm, B'_inter]
  · rwa [X_eq_pair, sInter_pair, inter_eq_self_of_subset_right Y_flat.subset_ground, inter_comm,
     B'_inter]

@[simp] theorem Modular_pair_comm (h : Modular_pair M X Y) : Modular_pair M Y X := by
  obtain ⟨B, B_Base, B_modular⟩ := h
  refine' ⟨B, B_Base, _⟩
  intro Ys Ys_sub Ys_ne
  rw [pair_comm] at Ys_sub
  exact B_modular Ys_sub Ys_ne

@[simp] theorem Modular_cl_empty (M : Matroid α) : Modular_flat M (M.cl ∅) := by
  intro Y Y_flat
  obtain ⟨B, h_B⟩ := M.exists_basis Y
  obtain ⟨B', B'_base, B_sub_B'⟩ := h_B.indep
  have B'_inter : Y ∩ B' = B
  · apply subset_antisymm _ _
    · rintro x ⟨x_B, x_Y⟩
      by_contra h_f
      apply ((B'_base.indep).subset (insert_subset x_Y B_sub_B')).not_dep
      exact h_B.insert_dep ⟨x_B, h_f⟩
    · intro x x_B
      exact ⟨h_B.subset x_B, B_sub_B' x_B⟩
  refine' ⟨B', B'_base, fun Ys Ys_sub Ys_ne ↦ _⟩
  obtain (Ys_eq_cl | Ys_eq_Y | Ys_eq_pair) := subset_pair_none Ys_ne Ys_sub
  · rw [Ys_eq_cl, sInter_singleton, Disjoint.inter_eq _, empty_basis_iff]
    · rw [disjoint_left]
      intro a a_cl a_B'
      rw [←loop_iff_mem_cl_empty, loop_iff_not_mem_base_forall] at a_cl
      exact a_cl B' B'_base a_B'
  · rwa [Ys_eq_Y, sInter_singleton, B'_inter]
  · rw [Ys_eq_pair, sInter_pair, ←Y_flat.cl, inter_eq_self_of_subset_left
    (M.cl_subset_cl (empty_subset _)), Disjoint.inter_eq _, empty_basis_iff]
    rw [disjoint_left]
    intro a a_cl a_B'
    rw [←loop_iff_mem_cl_empty, loop_iff_not_mem_base_forall] at a_cl
    exact a_cl B' B'_base a_B'

theorem Modular_pair_closure (M : Matroid α) (X Y : Set α) (h_union : M.Indep (X ∪ Y)) :
    M.Modular_pair (M.cl X) (M.cl Y) := by
  obtain ⟨B, B_Base, B_sub⟩ := h_union
  refine' ⟨B, B_Base, fun Ys Ys_sub Ys_ne ↦ _⟩
  obtain (eq_X | eq_Y | eq_inter) := subset_pair_none Ys_ne Ys_sub
  · rw [eq_X, sInter_singleton, B_Base.indep.cl_inter_eq_self_of_subset
   (union_subset_iff.1 B_sub).1]
    exact (((M.indep_iff_subset_base).2 ⟨B, B_Base, B_sub⟩).subset
     (subset_union_left _ _)).basis_cl
  · rw [eq_Y, sInter_singleton, B_Base.indep.cl_inter_eq_self_of_subset
   (union_subset_iff.1 B_sub).2]
    exact (((M.indep_iff_subset_base).2 ⟨B, B_Base, B_sub⟩).subset
     (subset_union_right _ _)).basis_cl
  · rw [eq_inter, sInter_pair, ←Indep.cl_inter_eq_inter_cl, B_Base.indep.cl_inter_eq_self_of_subset]
    · exact Indep.basis_cl (((M.indep_iff_subset_base).2 ⟨B, B_Base, B_sub⟩).subset
       (subset_union_of_subset_right (inter_subset_right _ _) _))
    · exact subset_trans (inter_subset_left _ _ ) (subset_trans (subset_union_left _ _) B_sub)
    · exact (M.indep_iff_subset_base).2 ⟨B, B_Base, B_sub⟩


def matroid_of_cut (M : Matroid α) (C : Set (Set α)) (hC : M.Modular_cut C) (e : α) (e_nE : e ∉ M.E) :
    Matroid α :=
  matroid_of_indep (insert e M.E)
  (fun X ↦ if (e ∈ X) then (M.Indep (X \ {e}) ∧ M.cl (X \ {e}) ∉ C) else M.Indep X)
  (by
    dsimp
    rw [if_neg (not_mem_empty _)]
    exact M.empty_indep
  )
  (by
    intro I J J_ind I_sub
    by_cases e_mem_I : e ∈ I
    · rw [if_pos e_mem_I]
      rw [if_pos (I_sub e_mem_I)] at J_ind
      refine' ⟨J_ind.1.subset (diff_subset_diff_left I_sub), fun clI_mem ↦ _⟩
      apply J_ind.2 (hC.2.1 (M.cl (I \ {e})) (M.cl (J \ {e}))
       clI_mem (M.cl_subset_cl (diff_subset_diff_left I_sub)) (M.cl_flat (J \ {e})))
    · rw [if_neg e_mem_I]
      by_cases e_mem_J : e ∈ J
      · rw [if_pos e_mem_J] at J_ind
        exact J_ind.1.subset (subset_diff_singleton I_sub e_mem_I)
      · rw [if_neg e_mem_J] at J_ind
        exact J_ind.subset I_sub
  )
  (by
    rintro I J I_ind I_nmax ⟨J_ind, J_max⟩
    have J_base_of_not_mem_e : e ∉ J → M.Base J
    · intro e_in_J
      rw [base_iff_maximal_indep]
      dsimp at J_ind
      rw [if_neg e_in_J] at J_ind
      refine' ⟨J_ind, fun X X_ind X_sub ↦ _⟩
      apply subset_antisymm X_sub (J_max _ X_sub)
      dsimp
      rwa [if_neg (not_mem_subset (X_ind.subset_ground) e_nE)]
    rw [mem_maximals_iff] at I_nmax
    push_neg at I_nmax
    obtain ⟨Y, Y_ind, I_sub_Y, I_ne_Y⟩ := I_nmax I_ind
    dsimp at Y_ind
    by_cases e_in_I : e ∈ I
    · rw [if_pos e_in_I] at I_ind
      by_cases e_in_J : e ∈ J
      · sorry --hardest case i think, leave for last
      ·
        have I_nb : ¬ M.Base (I \ {e})
        · intro I_Base
          rw [if_pos (I_sub_Y e_in_I)] at Y_ind
          apply (I_Base.dep_of_ssubset _ Y_ind.1.subset_ground).not_indep Y_ind.1
          rw [ssubset_iff_subset_ne]
          refine' ⟨diff_subset_diff_left I_sub_Y, fun diff_eq ↦ _⟩
          apply I_ne_Y (subset_antisymm I_sub_Y _)
          intro y y_in_Y
          by_cases y_eq_e : y = e
          · rwa [y_eq_e]
          · apply diff_subset I {e}
            rw [diff_eq]
            exact ⟨y_in_Y, y_eq_e⟩
        obtain ⟨j₂, hj₂⟩ := I_ind.1.exists_insert_of_not_base I_nb (J_base_of_not_mem_e e_in_J)
        have j₂I_nb : ¬ M.Base (insert j₂ (I \ {e}))
        · intro j₂I_base
        have extend : ∃ j₁ ∈ J \ I, ∃ j₂ ∈ J \ I, j₁ ≠ j₂ ∧ M.Indep (insert j₂ --this may be difficult
       (insert j₁ (I \ {e})))
        · sorry
--case involving finding 2 to add from j and using modularity to contradict I independence, not so
--bad
        obtain ⟨j₁, j₁_mem, j₂, j₂_mem, h_ne, ind⟩ := extend
        by_cases j₁_cl_mem_c : M.cl (insert j₁ (I \ {e})) ∈ C
        · by_cases j₂_cl_mem_c : M.cl (insert j₂ (I \ {e})) ∈ C
          · have pair := M.Modular_pair_closure (insert j₁ (I \ {e})) (insert j₂ (I \ {e}))
            rw [union_insert_eq] at pair
            have inter_mem_c:= hC.2.2 _ _ j₁_cl_mem_c j₂_cl_mem_c (pair ind)
            rw [←Indep.cl_inter_eq_inter_cl _, inter_insert_eq h_ne] at inter_mem_c
            · exact absurd inter_mem_c I_ind.2
            · rwa [union_insert_eq]
          · refine' ⟨j₂, j₂_mem, _⟩
            dsimp
            rw [if_pos (mem_insert_of_mem _ e_in_I), ←insert_diff_singleton_comm
             (ne_of_mem_of_not_mem j₂_mem.1 e_in_J) _, ]
            rw [insert_comm] at ind
            exact ⟨ind.subset (subset_insert _ _), j₂_cl_mem_c⟩
        · refine' ⟨j₁, j₁_mem, _⟩
          dsimp
          rw [if_pos (mem_insert_of_mem _ e_in_I), ←insert_diff_singleton_comm
           (ne_of_mem_of_not_mem j₁_mem.1 e_in_J) _, ]
          exact ⟨ind.subset (subset_insert _ _), j₁_cl_mem_c⟩
    · rw [if_neg e_in_I] at I_ind
      by_cases e_in_J : e ∈ J
      · dsimp at J_ind; rw [if_pos e_in_J] at J_ind --moderately difficult case
        by_cases cl_I_mem : M.cl I ∈ C --if cl(I) ∈ C, and every member of J-e cant be added, then J ⊂ cl(I)
        · by_contra' h_f
          have J_diff_sub_cl_I : J \ {e} ⊆ M.cl I
          · rintro j ⟨j_J, (j_ne : j ≠ e)⟩
            rw [I_ind.mem_cl_iff, or_comm, or_iff_not_imp_left]
            intro j_nI
            have not_ind:= h_f j ⟨j_J, j_nI⟩
            rw [if_neg _] at not_ind
            · apply dep_of_not_indep not_ind _
              rintro x (x_eq | x_sub)
              · rw [x_eq]
                apply (J_ind.1.subset_ground) ⟨j_J, j_ne⟩
              · apply I_ind.subset_ground x_sub
            rintro (e_eq | e_mem)
            · exact j_ne e_eq.symm
            · exact e_in_I e_mem
          have I_J_exch : ∃ i ∈ I \ (J \ {e}), M.Indep (insert i (J \ {e}))
          · apply J_ind.1.exists_insert_of_not_basis (subset_union_left _ I)
            · intro h_f
              apply J_ind.2 (hC.2.1 _ _ cl_I_mem _ (M.cl_flat _))
              rw [h_f.cl_eq_cl]
              exact M.cl_subset_cl (subset_union_right _ _)
            rw [basis_iff_indep_subset_cl]
            refine' ⟨I_ind, subset_union_right _ _, fun x ↦ _⟩
            rintro (x_J | x_I)
            · exact J_diff_sub_cl_I x_J
            · exact M.mem_cl_of_mem x_I
          obtain ⟨i, i_mem, i_ind⟩ := I_J_exch
          by_cases e_in_Y : e ∈ Y
          · rw [if_pos e_in_Y] at Y_ind
            apply Y_ind.2 (hC.2.1 _ _ cl_I_mem (M.cl_subset_cl _) (M.cl_flat _))
            exact subset_diff_singleton I_sub_Y e_in_I
          · rw [if_neg e_in_Y] at Y_ind
            have Y_insert : ∃ y ∈ Y \ I, M.Indep (insert y (insert i (J \ {e})))
            · obtain ⟨y, hy⟩ := Set.exists_of_ssubset (ssubset_iff_subset_ne.2 ⟨I_sub_Y, I_ne_Y⟩)
              refine' ⟨y, ⟨hy.1, hy.2⟩, _⟩
              rw [i_ind.insert_indep_iff_of_not_mem, mem_diff]
              · refine' ⟨Y_ind.subset_ground hy.1, fun y_cl ↦ _⟩
                obtain (mem_c | y_in_I) := I_ind.insert_indep_iff.1 (Y_ind.subset
                 (insert_subset hy.1 I_sub_Y))
                · apply mem_c.2 (cl_subset_cl_of_subset_cl (insert_subset (M.mem_cl_of_mem i_mem.1
                 I_ind.subset_ground) J_diff_sub_cl_I) y_cl)
                · exact hy.2 y_in_I
              · rintro (y_I | ⟨y_J, (y_ne_e : y ≠ e)⟩)
                · apply hy.2
                  rw [y_I]
                  exact i_mem.1
                apply h_f y ⟨y_J, hy.2⟩
                rw [mem_insert_iff, or_iff_left e_in_I, if_neg y_ne_e.symm]
                apply Y_ind.subset (insert_subset hy.1 I_sub_Y)
            obtain ⟨y, y_mem, y_ind⟩ := Y_insert
            have pair_cl:= hC.2.2 (M.cl (insert i (J \ {e}))) (M.cl (insert y (J \ {e})))
            have union_indep : M.Indep ((insert i (J \ {e})) ∪ (insert y (J \ {e})))
            · rwa [union_insert_eq]
            rw [←Indep.cl_inter_eq_inter_cl union_indep, inter_insert_eq (ne_of_mem_of_not_mem i_mem.1 y_mem.2)] at pair_cl
            apply J_ind.2 (pair_cl _ _ _)
            · by_contra insert_not_mem
              apply (J \ {e}).ne_insert_of_not_mem (J \ {e}) i_mem.2 (subset_antisymm (subset_insert _ _) _)
              rw [insert_diff_singleton_comm (ne_of_mem_of_not_mem i_mem.1 e_in_I) _] at insert_not_mem ⊢
              apply diff_subset_diff_left (J_max _ (subset_insert _ _))
              dsimp
              rw [if_pos (mem_insert_of_mem _ e_in_J)]
              refine' ⟨y_ind.subset (subset_trans _ (subset_insert _ _)), insert_not_mem⟩
              rw [insert_diff_singleton_comm (ne_of_mem_of_not_mem i_mem.1 e_in_I) _]
            · by_contra insert_not_mem
              apply (J \ {e}).ne_insert_of_not_mem (J \ {e}) _ (subset_antisymm (subset_insert y _) _)
              · rintro ⟨y_J, (y_ne_e : y ≠ e)⟩
                apply h_f y ⟨y_J, y_mem.2⟩
                rw [mem_insert_iff, or_iff_left e_in_I, if_neg y_ne_e.symm]
                apply Y_ind.subset (insert_subset y_mem.1 I_sub_Y)
              rw [insert_diff_singleton_comm (ne_of_mem_of_not_mem y_mem.1 e_in_Y)] at insert_not_mem ⊢
              apply diff_subset_diff_left (J_max _ (subset_insert _ _))
              dsimp
              rw [if_pos (mem_insert_of_mem _ e_in_J)]
              rw [insert_comm] at y_ind
              refine' ⟨y_ind.subset (subset_trans _ (subset_insert _ _)), insert_not_mem⟩
              rw [insert_diff_singleton_comm (ne_of_mem_of_not_mem y_mem.1 e_in_Y)]
            apply M.Modular_pair_closure _ _ union_indep
        · refine' ⟨e, ⟨e_in_J, e_in_I⟩, _⟩
          dsimp
          rw [if_pos (mem_insert e I), insert_diff_self_of_not_mem e_in_I]
          exact ⟨I_ind, cl_I_mem⟩
      · have I_not_base : ¬ M.Base I --easiest case, e is in neither - requires some effort to show I not a base
        · intro h_f
          by_cases e_in_Y : e ∈ Y
          · rw [if_pos e_in_Y, Spanning.cl_eq _] at Y_ind
            · apply (ne_insert_of_not_mem J e_in_J) (subset_antisymm (subset_insert e J) (J_max _ (subset_insert e J)))
              dsimp at J_ind ⊢
              rw [if_pos (mem_insert _ _), insert_diff_self_of_not_mem e_in_J, (J_base_of_not_mem_e e_in_J).cl_eq]
              rw [if_neg e_in_J] at J_ind
              exact ⟨J_ind, Y_ind.2⟩
            rw [spanning_iff_superset_base (Y_ind.1.subset_ground)]
            refine' ⟨I, h_f, subset_diff_singleton I_sub_Y e_in_I⟩
          · rw [if_neg e_in_Y] at Y_ind
            apply (h_f.dep_of_ssubset (I_ne_Y.ssubset_of_subset I_sub_Y)
             Y_ind.subset_ground).not_indep Y_ind
        obtain ⟨x, x_mem, x_ind⟩ := I_ind.exists_insert_of_not_base I_not_base (J_base_of_not_mem_e e_in_J)
        refine' ⟨x, x_mem, _⟩
        dsimp
        rwa [if_neg _]
        rw [mem_insert_iff]; push_neg
        exact ⟨(ne_of_mem_of_not_mem x_mem.1 e_in_J).symm, e_in_I⟩








  )
  sorry sorry
