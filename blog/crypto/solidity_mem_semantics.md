@def title = "Formal Model of Solidity Memory Semantics"
@def published = "29 November 2025"
@def tags = ["crypto", "smart-contract", "block-chain", "eth"]

# Formal Model of Solidity Memory Semantics

## 1. Data Locations as Disjoint Address Spaces

Let $L = \{\text{storage}, \text{memory}, \text{calldata}\}$ be the set of data locations.

For each location $\ell \in L$, we have a disjoint address space $A_\ell$:
$$A_{\text{storage}} \cap A_{\text{memory}} \cap A_{\text{calldata}} = \emptyset$$

Each address $a \in A_\ell$ maps to a value via $M_\ell : A_\ell \to V$ where $V$ is the value domain.

**Intuition:** Think of storage as the blockchain ledger, memory as scratch RAM during execution, and calldata as immutable transaction input. These are completely separate "universes" - an address in one space means nothing in another.

## 2. Value Types vs Reference Types

### Value Types
Let $T_v = \{\texttt{uint}, \texttt{bool}, \texttt{address}, \ldots\}$.

For $t \in T_v$, a variable $x$ stores the value directly: $x \in V$

**Assignment:** $y := x$ means $y$ gets a copy of $x$'s value.

### Reference Types  
Let $T_r = \{\texttt{string}, \texttt{array}, \texttt{struct}, \ldots\}$.

For $t \in T_r$, a variable $x$ stores a pointer: $x = (a, \ell)$ where $a \in A_\ell$

**Key insight:** The variable doesn't hold the data - it holds *where* the data lives.

## 3. Assignment Within Same Location (Aliasing)

For reference variables $x = (a_x, \ell)$ and $y = (a_y, \ell)$ in the same location $\ell$:

$$y := x \implies a_y = a_x$$

Both now point to the same address. Modifying through $y$ affects $x$:
$$M_\ell(a_y) := v \implies M_\ell(a_x) = v$$

**Why?** Within one memory space, assignment just copies the pointer, not the data.

## 4. Assignment Across Different Locations (Copying)

For $x = (a_x, \ell_1)$ and $y = (a_y, \ell_2)$ where $\ell_1 \neq \ell_2$:

$$y := x \implies M_{\ell_2}(a_y) := M_{\ell_1}(a_x)$$

The *data* is copied from one address space to another. Now:
$$M_{\ell_2}(a_y) := v \not\Rightarrow M_{\ell_1}(a_x) = v$$

**Why?** You can't have a pointer from storage to memory - they're disjoint spaces. Must copy the actual data.

## 5. Function Modifiers as State Predicates

Let $S$ represent blockchain state (all storage variables) and $C$ represent context (block data, msg data, etc.).

**Pure functions:** $f : \text{Params} \to \text{Result}$
$$\text{pure} \iff f \text{ accesses neither } S \text{ nor } C$$

**View functions:** $f : S \times C \times \text{Params} \to \text{Result}$
$$\text{view} \iff f \text{ may read } S \text{ and } C \text{ but } \forall s \in S : s' = s \text{ (no modification)}$$

**State-modifying:** Can both read and write $S$.

## 6. Concrete Example with Formal Notation

```solidity
uint[] storage arr1;           // arr1 = (a₁, storage)
uint[] memory arr2 = arr1;     // arr2 = (a₂, memory)
uint[] memory arr3 = arr2;     // arr3 = (a₃, memory)
```

**Step by step:**
1. $\texttt{arr1} = (a_1, \text{storage})$ where $a_1 \in A_{\text{storage}}$
2. $\texttt{arr2} = (a_2, \text{memory})$ where $a_2 \in A_{\text{memory}}$
   - Since $\text{storage} \neq \text{memory}$: $M_{\text{memory}}(a_2) := M_{\text{storage}}(a_1)$ (COPY)
3. $\texttt{arr3} = (a_3, \text{memory})$
   - Since both in $\text{memory}$: $a_3 := a_2$ so $a_3 = a_2$ (ALIAS)

**Result:**
- Modifying `arr3[0]` also changes `arr2[0]` (same address $a_2 = a_3$)
- Neither affects `arr1` (different location, was copied)

## 7. The Core Rules

$$
\begin{align}
&\text{Value types:} && x := y &&\implies \text{always COPY} \\
&\text{Reference, same } \ell: && (a_x, \ell) := (a_y, \ell) &&\implies a_x = a_y \text{ (ALIAS)} \\
&\text{Reference, different } \ell: && (a_x, \ell_1) := (a_y, \ell_2) &&\implies \text{COPY where } \ell_1 \neq \ell_2
\end{align}
$$

## 8. Why the `memory` Keyword?

For reference types, Solidity needs to know which address space $A_\ell$ your pointer lives in:

```solidity
function f() public pure returns (string memory) {  // Must specify!
    return "Hello";
}
```

Without specifying the location, the compiler can't determine:
- Whether assignment should alias or copy
- How to allocate/access the data
- What gas costs apply

Value types don't need this because they always copy - no ambiguity about location.