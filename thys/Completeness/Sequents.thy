header "Sequents"

theory Sequents = Formula: 

types sequent = "formula list"

constdefs evalS :: "[model,vbl => object,formula list] => bool"
  "evalS M phi fs == ? f : set fs . evalF M phi f = True"

lemma evalS_nil[simp]: "evalS M phi [] = False"
  by(simp add: evalS_def)

lemma evalS_cons[simp]: "evalS M phi (A # Gamma) = (evalF M phi A | evalS M phi Gamma)"
  apply(simp add: evalS_def) done

lemma evalS_append: "evalS M phi (Gamma @ Delta) = (evalS M phi Gamma | evalS M phi Delta)"
  by(force simp add: evalS_def)

lemma evalS_equiv[rule_format]: "(equalOn (freeVarsFL Gamma) f g) --> (evalS M f Gamma = evalS M g Gamma)"
  apply (induct Gamma, simp, rule)
  apply(simp add: freeVarsFL_cons)
  apply(drule_tac equalOn_UnD)
  apply (erule impE, simp, simp)
  apply(rule arg_cong) back
  apply(simp add: evalF_equiv)
  done


constdefs modelAssigns :: "[model] => (vbl => object) set"
  "modelAssigns M == { phi . range phi <= objects M }"

lemma modelAssignsI: "range f <= objects M \<Longrightarrow> f : modelAssigns M" 
  apply(simp add: modelAssigns_def) done

lemma modelAssignsD: "f : modelAssigns M \<Longrightarrow> range f <= objects M" 
  apply(simp add: modelAssigns_def) done
  
constdefs
  validS           :: "formula list => bool"
  "validS fs == ! M . ! phi : modelAssigns M . evalS M phi fs = True"


subsection "Rules"

types rule     = "sequent * (sequent set)"

constdefs
  concR	:: "rule => sequent"
  "concR   == %   (conc,prems) . conc"

  premsR	:: "rule => sequent set"
  "premsR  == %   (conc,prems) . prems"

constdefs
  mapRule	:: "(formula => formula) => rule => rule"
  "mapRule == % f (conc,prems) . (map f conc,(map f) ` prems)"

lemma mapRuleI: "!!f. [| A = map f a; B = (map f) ` b |] ==> (A,B) = mapRule f (a,b)"
  apply(simp add: mapRule_def) done
    -- "FIXME tjr would like symmetric"


subsection "Deductions"

consts deductions  :: "rule set => formula list set"

inductive "deductions(rules)"
  (******
   * Given a set of rules,
   *   1. Given a rule conc/prem(i) in rules,
   *       and the prem(i) are deductions from rules,
   *       then conc is a deduction from rules.
   *   2. can derive permutation of any deducible formula list.
   *      (supposed to be multisets not lists).
   ******)
  intros
    inferI: "[| (conc,prems) : rules;
	       prems : Pow(deductions(rules))
	    |] ==> conc : deductions(rules)"
(*
    perms   "[| permutation conc' conc;
                conc' : deductions(rules)
	     |] ==> conc : deductions(rules)"
*)
  monos Pow_mono

lemma mono_deductions: "[| A <= B |] ==> deductions(A) <= deductions(B)"
  apply(best intro: deductions.inferI elim: deductions.induct) done
  
(*lemmas deductionsMono = mono_deductions*)

(*
-- "tjr following should be subsetD?"
lemmas deductionSubsetI = mono_deductions[THEN subsetD]
thm deductionSubsetI
*)

(******
 * (f : formula -> formula) extended structurally over rules, deductions etc...
 * (((If f maps rules into themselves then can consider mapping derivation trees.)))
 * (((Is the asm necessary - think not?)))
 * The mapped deductions from the rules are same as
 * the deductions from the mapped rules.
 *
 * WHY:
 *
 * map f `` deductions rules <= deductions (mapRule f `` rules)     (this thm)
 *                           <= deductions rules                    (closed)
 *
 * If rules are closed under f then so are deductions.
 * Can take f = (subst u v) and have application to exercise #1.
 *
 * Q: maybe also make f dual mapping, (what about quantifier side conditions...?).
 ******)

(*
lemma map_deductions: "map f ` deductions rules <= deductions (mapRule f ` rules)"
  apply(rule subsetI)
  apply (erule_tac imageE, simp)
  apply(erule deductions.induct)
  apply(blast intro: deductions.inferI mapRuleI)
  done

lemma deductionsCloseRules: "! (conc,prems) : S . prems <= deductions R --> conc : deductions R ==> deductions (R Un S) = deductions R"
  apply(rule equalityI)
  prefer 2
  apply(rule mono_deductions) apply blast
  apply(rule subsetI)
  apply (erule_tac deductions.induct, simp) apply(erule conjE) apply(thin_tac "prems \<subseteq> deductions (R \<union> S)")
  apply(erule disjE)
  apply(rule inferI) apply assumption apply force
  apply blast
  done
*)


subsection "Basic Rule sets"

consts
    Axioms    :: "rule set"
    Conjs     :: "rule set"
    Disjs     :: "rule set"
    Alls      :: "rule set"
    Exs       :: "rule set"
    Weaks     :: "rule set"
    Contrs    :: "rule set"
    Cuts      :: "rule set"
    Perms     :: "rule set"
    DAxioms   :: "rule set"

defs
    Axioms_def:     "Axioms  == { z. ? p vs.              z = ([FAtom Pos p vs,FAtom Neg p vs],{}) }"
    Conjs_def:      "Conjs   == { z. ? A0 A1 Delta Gamma. z = (FConj Pos A0 A1#Gamma @ Delta,{A0#Gamma,A1#Delta}) }"
    Disjs_def:      "Disjs   == { z. ? A0 A1       Gamma. z = (FConj Neg A0 A1#Gamma,{A0#A1#Gamma}) }"
    Alls_def:       "Alls    == { z. ? A x         Gamma. z = (FAll Pos A#Gamma,{instanceF x A#Gamma}) & x ~: freeVarsFL (FAll Pos A#Gamma) }"
    Exs_def:        "Exs     == { z. ? A x         Gamma. z = (FAll Neg A#Gamma,{instanceF x A#Gamma})}"
    Weaks_def:      "Weaks   == { z. ? A           Gamma. z = (A#Gamma,{Gamma})}"
    Contrs_def:     "Contrs  == { z. ? A           Gamma. z = (A#Gamma,{A#A#Gamma})}"
    Cuts_def:       "Cuts    == { z. ? C Delta     Gamma. z = (Gamma @ Delta,{C#Gamma,FNot C#Delta})}"
    Perms_def:      "Perms   == { z. ? Gamma Gamma'     . z = (Gamma,{Gamma'}) & Gamma <~~> Gamma'}"

    DAxioms_def:    "DAxioms == { z. ? p vs.              z = ([FAtom Neg p vs,FAtom Pos p vs],{}) }"


lemma AxiomI: "[| Axioms <= A |] ==> [FAtom Pos p vs,FAtom Neg p vs] : deductions(A)"
  apply(rule deductions.inferI)
  apply(auto simp add: Axioms_def) done

lemma DAxiomsI: "[| DAxioms <= A |] ==> [FAtom Neg p vs,FAtom Pos p vs] : deductions(A)"
  apply(rule deductions.inferI)
  apply(auto simp add: DAxioms_def) done

lemma DisjI: "[| A0#A1#Gamma : deductions(A); Disjs <= A |] ==> (FConj Neg A0 A1#Gamma) : deductions(A)"
  apply(rule deductions.inferI)
  apply(auto simp add: Disjs_def) done

lemma ConjI: "[| (A0#Gamma) : deductions(A); (A1#Delta) : deductions(A); Conjs <= A |] ==> FConj Pos A0 A1#Gamma @ Delta : deductions(A)"
  apply(rule_tac prems="{A0#Gamma,A1#Delta}" in deductions.inferI)
  apply(auto simp add: Conjs_def) apply force done

lemma AllI: "[| instanceF w A#Gamma : deductions(R); w ~: freeVarsFL (FAll Pos A#Gamma); Alls <= R |] ==> (FAll Pos A#Gamma) : deductions(R)"
  apply(rule_tac prems="{instanceF w A#Gamma}" in deductions.inferI)
  apply(auto simp add: Alls_def) done

lemma ExI: "[| instanceF w A#Gamma : deductions(R); Exs <= R |] ==> (FAll Neg A#Gamma) : deductions(R)"
  apply(rule_tac prems = "{instanceF w A#Gamma}" in deductions.inferI)
  apply(auto simp add: Exs_def) done

lemma WeakI: "[| Gamma : deductions R; Weaks <= R |] ==> A#Gamma : deductions(R)"
  apply(rule_tac prems="{Gamma}" in deductions.inferI)
  apply(auto simp add: Weaks_def) done

lemma ContrI: "[| A#A#Gamma : deductions R; Contrs <= R |] ==> A#Gamma : deductions(R)"
  apply(rule_tac prems="{A#A#Gamma}" in deductions.inferI)
  apply(auto simp add: Contrs_def) done

lemma PermI: "[| Gamma' : deductions R; Gamma <~~> Gamma'; Perms <= R |] ==> Gamma : deductions(R)"
  apply(rule_tac prems="{Gamma'}" in deductions.inferI)
  apply(auto simp add: Perms_def) done


subsection "Derived Rules"

lemma WeakI1: "[| Gamma : deductions(A); Weaks <= A |] ==> (Delta @ Gamma) : deductions(A)"
  apply (induct Delta, simp)
  apply(auto intro: WeakI) done

lemma WeakI2: "[| Gamma : deductions(A); Perms <= A; Weaks <= A |] ==> (Gamma @ Delta) : deductions(A)"
  apply(blast intro: PermI perm_append_swap WeakI1) done

lemma SATAxiomI: "[| Axioms <= A; Weaks <= A; Perms <= A; forms = [FAtom Pos n vs,FAtom Neg n vs] @ Gamma |] ==> forms : deductions(A)"
  apply(simp only:)
  apply(blast intro: WeakI2 AxiomI)
  done
    
lemma DisjI1: "[| (A1#Gamma) : deductions(A); Disjs <= A; Weaks <= A |] ==> FConj Neg A0 A1#Gamma : deductions(A)"
  apply(blast intro: DisjI WeakI)
  done

lemma DisjI2: "!!A. [| (A0#Gamma) : deductions(A); Disjs <= A; Weaks <= A; Perms <= A |] ==> FConj Neg A0 A1#Gamma : deductions(A)"
  apply(rule DisjI)
  apply(rule PermI[OF _ perm.swap])
  apply(rule WeakI)
  .

    -- "FIXME the following 4 lemmas could all be proved for the standard rule sets using monotonicity as below"
    -- "we keep proofs as in original, but they are slightly ugly, and do not state what is intuitively happening"
lemma perm_tmp4: "Perms \<subseteq> R \<Longrightarrow> A @ (a # list) @ (a # list) : deductions R \<Longrightarrow> (a # a # A) @ list @ list : deductions R"
  apply (rule PermI, auto)
  apply(simp add: perm_count_conv count_append) done

lemma weaken_append[rule_format]: "Contrs <= R ==> Perms <= R ==> !A. A @ Gamma @ Gamma : deductions(R) -->  A @ Gamma : deductions(R)"
  apply (induct_tac Gamma, simp, rule) apply rule
  apply(drule_tac x="a#a#A" in spec)
  apply(erule_tac impE)
  apply(rule perm_tmp4) apply(assumption, assumption)
  apply(thin_tac "A @ (a # list) @ a # list \<in> deductions R")
  apply simp
  apply(frule_tac ContrI) apply assumption
  apply(thin_tac "a # a # A @ list \<in> deductions R")
  apply(rule PermI) apply assumption 
  apply(simp add: perm_count_conv count_append) 
  by assumption
  -- "FIXME horrible"

lemma ListWeakI: "Perms <= R ==> Contrs <= R ==> x # Gamma @ Gamma : deductions(R) ==> x # Gamma : deductions(R)"
  by(rule weaken_append[of R "[x]" Gamma, simplified])
    
lemma ConjI': "[| (A0#Gamma) : deductions(A);  (A1#Gamma) : deductions(A); Contrs <= A; Conjs <= A; Perms <= A |] ==> FConj Pos A0 A1#Gamma : deductions(A)"
  apply(rule ListWeakI, assumption, assumption)
  apply(rule ConjI) .



subsection "Standard Rule Sets For Predicate Calculus"

constdefs
  PC        :: "rule set"
  "PC        == Union {Perms,Axioms,Conjs,Disjs,Alls,Exs,Weaks,Contrs,Cuts}"

constdefs
  CutFreePC :: "rule set"
  "CutFreePC == Union {Perms,Axioms,Conjs,Disjs,Alls,Exs,Weaks,Contrs}"

lemma rulesInPCs: "Axioms <= PC" "Axioms <= CutFreePC"
  "Conjs  <= PC" "Conjs  <= CutFreePC"
  "Disjs  <= PC" "Disjs  <= CutFreePC"
  "Alls   <= PC" "Alls   <= CutFreePC"
  "Exs    <= PC" "Exs    <= CutFreePC"
  "Weaks  <= PC" "Weaks  <= CutFreePC"
  "Contrs <= PC" "Contrs <= CutFreePC"
  "Perms  <= PC" "Perms  <= CutFreePC"
  "Cuts   <= PC"
  "CutFreePC <= PC"
  apply(auto simp: PC_def CutFreePC_def)
  done


subsection "Monotonicity for CutFreePC deductions"

  -- "these lemmas can be used to replace complicated permutation reasoning above"
  -- "essentially if x is a deduction, and set x subset set y, then y is a deduction"

constdefs inDed :: "formula list => bool"
  "inDed xs == xs : deductions CutFreePC"

lemma perm: "! xs ys. xs <~~> ys --> (inDed xs = inDed ys)"
  apply(subgoal_tac "! xs ys. xs <~~> ys --> inDed xs --> inDed ys")
  apply (blast intro: perm_sym, clarify)
  apply(simp add: inDed_def)
  apply (rule PermI, assumption)
  apply(rule perm_sym) apply assumption
  by(blast intro!: rulesInPCs)

lemma contr: "! x xs. inDed (x#x#xs) --> inDed (x#xs)"
  apply(simp add: inDed_def)
  apply(blast intro!: ContrI rulesInPCs)
  done

lemma weak: "! x xs. inDed xs --> inDed (x#xs)"
  apply(simp add: inDed_def)
  apply(blast intro!: WeakI rulesInPCs)
  done

lemma inDed_mono'[simplified inDed_def]: "set x <= set y ==> inDed x ==> inDed y"
  using perm_weak_contr_mono[OF perm contr weak] .

lemma inDed_mono[simplified inDed_def]: "inDed x ==> set x <= set y ==> inDed y"
  using perm_weak_contr_mono[OF perm contr weak] .


end
