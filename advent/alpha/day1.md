The sleigh's flight recorder dumps raw memory. Over the years, four firmware builds wrote the same record with four different packings, and all of them ended up in the same file.

Every build wrote this record:

```ahk2
struct Reading {
    sensor      : UInt8
    timestamp   : UInt32
    temperature : Int16
    flags       : UInt8
    odometer    : Int64
}
```

The file is a run of segments, back to back, until the data ends. A segment starts with a 3-byte header: `pack` as a UInt8, then `count` as a UInt16, with no padding between them. After the header come `count` readings laid out with that pack value. With pack 8 a reading is 24 bytes, with fields at offsets 0, 4, 8, 10 and 16. With pack 1 it is 16 bytes. Pack 2 and pack 4 are yours to work out.

A reading is valid when bit 0 of `flags` is set. A sensor's latest reading is its valid reading with the largest `timestamp`; timestamps never repeat. The score of a set of readings is the sum, over every sensor that has a valid reading, of `temperature` x `odometer` from that sensor's latest reading.

```text
0803000325CF73E8030000F4FF058FAB5F5BDB881300000000000007D7347700
286BEE140081825045E4DAB00400000000000003E6452FC4090000F8FF028386
9ECB79E01500000000000001020003005ED0B20F0001581B000000000000094D
000000E2FF036400000000000000
```

This example holds a pack 8 segment with three readings, then a pack 1 segment with two:

| Segment | sensor | timestamp | temperature | flags | odometer |
| :-- | --: | --: | --: | --: | --: |
| 1 (pack 8) | 3 | 1000 | -12 | 5 | 5000 |
| 1 (pack 8) | 7 | 4000000000 | 20 | 129 | 1200 |
| 1 (pack 8) | 3 | 2500 | -8 | 2 | 5600 |
| 2 (pack 1) | 3 | 3000000000 | 15 | 1 | 7000 |
| 2 (pack 1) | 9 | 77 | -30 | 3 | 100 |

**Part 1.** The first segment always uses pack 8. Score only that segment. In the example, sensor 3's reading at 2500 is not valid, so its latest is the reading at 1000. The score is -12 x 5000 + 20 x 1200 = **-36000**.

What is the score of the first segment?

**Alpha requirements.** Declare `Reading` with `struct` and read every record through `Reading.At(address)`. Produce the four packings with `#StructPack` or the `pack` option of `DefineProp`. Call no `NumGet`.

**Left for you to discover.** How far a `#StructPack` directive reaches, and whether each variant's `Size` matches the layout rules.

<!-- part2 -->

**Part 2.** Score every reading in the file. In the example, sensor 3's latest reading is now the one at 3000000000, and the score is 15 x 7000 + 20 x 1200 - 30 x 100 = **126000**.

What is the score of the whole file?
