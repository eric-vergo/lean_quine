import Quine

/-!
# QuineFacts -- an honest round-trip for the quine's encoder

These lemmas live OUTSIDE `Quine.lean`, so they add nothing to the encoded payload, and they
justify the encoding scheme by a real induction rather than by kernel evaluation. The claim
is the round-trip the quine relies on: decoding the base-1000 encoding of a list of groups
recovers exactly that list. `Quine.N` is precisely `encode` of this file's group list, and
`Quine.decode` is the same peeling used inside the quine.

Everything here is sorry-free and `native_decide`-free -- ordinary structural induction with
`omega` for the arithmetic.
-/
namespace QuineFacts

/-- Encode a list of base-1000 groups into a single `Nat` (most significant first) behind a
leading sentinel `1`. `Quine.N` is exactly `encode` of this file's group list. -/
def encode (l : List Nat) : Nat := l.foldl (fun n k => n * 1000 + k) 1

/-- A reverse (append-a-singleton) induction principle for lists, derived from ordinary
structural recursion through `List.reverse`. -/
theorem reverseRecOn {α : Type u} {motive : List α → Prop} (l : List α)
    (nil : motive [])
    (append_singleton : ∀ (l : List α) (a : α), motive l → motive (l ++ [a])) : motive l := by
  have h : ∀ m : List α, motive m.reverse := by
    intro m
    induction m with
    | nil => exact nil
    | cons a as ih => rw [List.reverse_cons]; exact append_singleton as.reverse a ih
  have := h l.reverse
  rwa [List.reverse_reverse] at this

/-- `encode` never drops below the sentinel `1`. -/
theorem one_le_encode (l : List Nat) : 1 ≤ encode l := by
  suffices h : ∀ s, 1 ≤ s → 1 ≤ l.foldl (fun n k => n * 1000 + k) s by
    exact h 1 (Nat.le_refl 1)
  induction l with
  | nil => intro s hs; simpa using hs
  | cons k ks ih => intro s hs; simp only [List.foldl_cons]; exact ih _ (by omega)

/-- Appending a group multiplies the encoding by the base and adds the group. -/
theorem encode_append (l : List Nat) (a : Nat) : encode (l ++ [a]) = encode l * 1000 + a := by
  simp [encode, List.foldl_append]

/-- The generalized round-trip: decoding the encoding of a group list (every group `< 1000`,
with at least `length + 1` fuel) prepends exactly that list onto the accumulator. -/
theorem decode_encode_append :
    ∀ (l : List Nat), (∀ k ∈ l, k < 1000) →
      ∀ (fuel : Nat), l.length < fuel → ∀ (acc : List Nat),
        Quine.decode fuel (encode l) acc = l ++ acc := by
  intro l
  induction l using reverseRecOn with
  | nil =>
    intro _ fuel _ acc
    simp only [encode, List.foldl_nil, List.nil_append]
    cases fuel with
    | zero => rfl
    | succ f => simp [Quine.decode]
  | append_singleton l a ih =>
    intro h fuel hlen acc
    simp only [List.mem_append, List.mem_singleton] at h
    have hmem : ∀ k ∈ l, k < 1000 := fun k hk => h k (Or.inl hk)
    have ha : a < 1000 := h a (Or.inr rfl)
    have hone := one_le_encode l
    simp only [List.length_append, List.length_cons, List.length_nil] at hlen
    obtain ⟨f, rfl⟩ : ∃ f, fuel = f + 1 := ⟨fuel - 1, by omega⟩
    rw [encode_append]
    have hlt : ¬ (encode l * 1000 + a < 2) := by omega
    have hdiv : (encode l * 1000 + a) / 1000 = encode l := by omega
    have hmod : (encode l * 1000 + a) % 1000 = a := by omega
    simp only [Quine.decode, if_neg hlt, hdiv, hmod]
    rw [ih hmem f (by omega) (a :: acc)]
    simp

/-- The round-trip stated on the nose: `decode` inverts `encode` for any list of valid
base-1000 groups (`Quine.N` is one such encoding, with the marker group `1 < 1000`). -/
theorem decode_encode (l : List Nat) (h : ∀ k ∈ l, k < 1000) :
    Quine.decode (l.length + 1) (encode l) [] = l := by
  simpa using decode_encode_append l h (l.length + 1) (Nat.lt_succ_self _) []

end QuineFacts
