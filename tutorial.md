# Ceptre Tutorial: Getting Started

## Overview

Ceptre is a *linear logic programming language* created by [Chris
Martens](http://www.cs.cmu.edu/~cmartens). It can be used to specify evolving
systems with lots of independent parts in a concise way.

Linear logic programming at a glance means writing rules of the form

```
a * b * c -o d * e
```

that specify state transitions on a component-wise basis: this rule says
that if our state contains an `a`, a `b`, and a `c`, then we can replace
that part of the state with `d` and `e`.

This style of programming becomes more useful when we can write *rule
schema* like

```
arm_holding A * clear B -o on A B * clear A * arm_free
```

where `A` and `B` *range over* entities in the world we are simulating. (By
convention, Ceptre uses capital letters as variables that may range over
all appropriately-typed entities.)

In this tutorial, we provide step-by-step instructions for running your
first Ceptre program and learning enough to write your own.


## Example

### Hello World

The ``hello world'' example of Ceptre is a program with two predicates and
a single rule.

```
a : pred.
b : pred.

stage main = { 
  rule : a -o b.
}

#trace _ main {a,a,a}.
```

### Syntax explained

### Predicates

### Stages

### Interactivity

### Types

## Operational Semantics
