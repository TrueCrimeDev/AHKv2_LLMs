The cargo manifest arrives minutes before launch, in a format that changes every year. The only description of this year's format is the schema at the top of the file, so nothing about it can be written down ahead of time.

Your input has two blocks separated by a blank line. The first block defines struct types, one per line, as `Name pack=N { field: Type, ... }`. A field's type is a numeric type (`Int8`, `UInt8`, `Int16`, `UInt16`, `Int32`, `UInt32`, `Int64`), a struct defined on an earlier line, or either of those followed by `[N]` for an array of N elements.

The second block starts with `data Root count`. The hex that follows holds `count` records of type `Root`, back to back.

The layout rules from the alpha tier's rules page apply. A nested struct keeps the layout its own pack gave it. The parent's pack only limits where the nested struct may start.

```text
Tag pack=1 { code: UInt8, lot: UInt32 }
Crate pack=8 { id: UInt16, weight: Int32, dims: UInt8[3], tag: Tag }
Pallet pack=2 { bay: Int8, crates: Crate[2], mass: Int64 }

data Pallet 2
FD1BF4015ABC50FBFFFF0405060970110100F50106DC50000000010102C80C00
000000046BF4140000000704FFFF110E2C0000000909090100286BEE0200B225
FBFFFFFF000001000300000006FFFFFFFFFFFFFF
```

The example's types lay out like this:

| Type | Field offsets | Alignment | Size |
| :-- | :-- | --: | --: |
| Tag | code 0, lot 1 | 1 | 5 |
| Crate | id 0, weight 4, dims 8, tag 11 | 4 | 16 |
| Pallet | bay 0, crates 2, mass 34 | 2 | 42 |

`Crate` has alignment 4, but `Pallet` uses pack 2, so `crates` starts at offset 2.

**Part 1.** Add up the sizes of every type the schema defines. In the example that is 5 + 16 + 42 = **63**.

What is the sum of the sizes of all types in your schema?

**Alpha requirements.** Write no struct declarations by hand. Build every type at run time with `Class(Struct)` and `DefineProp`, using its `type` and `pack` options and `Type[N]` for arrays. Take every size from `Size`, reach the data with `At()`, and call no `NumGet`.

**Left for you to discover.** Whether a run-time struct's `Size` follows the nested pack rule above, and how to walk the fields of a type you built without knowing their names in advance.

<!-- part2 -->

**Part 2.** Decode every record and add up every numeric value inside it, at any depth, through nested structs and arrays alike. The example's two pallets sum to 90000070118 and 4000065365, for a total of **94000135483**.

What is the sum of every numeric value in your data?
