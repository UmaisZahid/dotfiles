---
urls:
  - https://htmx.org/essays/locality-of-behaviour/
  - https://peps.python.org/pep-0020/
---

# Core Principles

## Goals

- Newcomers should understand intent without hidden context.
- Future maintainers should find entry points and change locations quickly.
- The implementation should explain why it is written this way.

## Decision Order

1. Correctness
2. Readability, maintainability, locality of behaviour
3. Extensibility and evolution cost
4. Performance and optimization

## Principles

- Locality of Behaviour (LoB)
- The Zen of Python

## Locality of Behaviour (LoB) 
(by Carson Gross)

“The primary feature for easy maintenance is locality: Locality is that characteristic of source code that enables a programmer to understand that source by looking at only a small portion of it.” – Richard Gabriel

Locality of Behaviour is the principle that:
> The behaviour of a unit of code should be as obvious as possible by looking only at that unit of code

The LoB principle is a simple prescriptive formulation of the quoted statement from Richard Gabriel. In as much as it is possible, and in balance with other concerns, developers should strive to make the behaviour of a code element obvious on inspection.

## The Zen of Python
(by Tim Peters)

Beautiful is better than ugly.
Explicit is better than implicit.
Simple is better than complex.
Complex is better than complicated.
Flat is better than nested.
Sparse is better than dense.
Readability counts.
Special cases aren't special enough to break the rules.
Although practicality beats purity.
Errors should never pass silently.
Unless explicitly silenced.
In the face of ambiguity, refuse the temptation to guess.
There should be one-- and preferably only one --obvious way to do it.
Although that way may not be obvious at first unless you're Dutch.
Now is better than never.
Although never is often better than *right* now.
If the implementation is hard to explain, it's a bad idea.
Namespaces are one honking great idea -- let's do more of those!
If the implementation is easy to explain, it may be a good idea.

