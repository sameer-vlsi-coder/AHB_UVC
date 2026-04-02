# AHB UVC — AMBA AHB Universal Verification Component

A complete UVM-based (Universal Verification Methodology) verification environment for the **AMBA AHB (Advanced High-performance Bus)** protocol, written in SystemVerilog. This UVC provides everything you need to stimulate, monitor, and check an AHB interface in simulation.

---

## Table of Contents

- [Overview](#overview)
- [What is AHB?](#what-is-ahb)
- [Architecture](#architecture)
- [Project Structure](#project-structure)
- [File Descriptions](#file-descriptions)
- [Key Features](#key-features)
- [AHB Signal Reference](#ahb-signal-reference)
- [Supported Transfer Types](#supported-transfer-types)
- [How to Run](#how-to-run)
- [Available Tests](#available-tests)
- [Scoreboard and Checking](#scoreboard-and-checking)
- [Coverage](#coverage)
- [Assertions](#assertions)
- [Prerequisites](#prerequisites)

---

## Overview

This project implements a **UVM-compliant UVC** for the AHB bus protocol. It is structured to be reusable and extensible — you can plug it into any SoC or IP verification environment that uses the AHB bus.

The environment includes:
- A **Master Agent** that generates and drives AHB transactions
- A **Slave Agent** that responds to incoming AHB requests
- A **Monitor** that passively observes the bus on both sides
- A **Scoreboard** that compares master-side and slave-side transactions
- A **Coverage Collector** that tracks functional coverage
- **Assertions** to catch protocol violations in real time

---

## What is AHB?

AHB (Advanced High-performance Bus) is part of ARM's AMBA (Advanced Microcontroller Bus Architecture) specification. It is a high-bandwidth bus used to connect high-performance components in a chip — things like processors, DMA controllers, and on-chip memories.

Key characteristics of AHB:
- **Pipelined** address and data phases (the next address is sent while the current data is being transferred)
- **Burst transfers** for efficient bulk data movement (INCR, WRAP, SINGLE modes)
- **Multiple master support** with an arbiter to decide which master gets the bus
- **Single shared bus** with a master-slave topology

---

## Architecture

The UVC follows the standard UVM layered testbench architecture:

```
┌──────────────────────────────────────────────────────────┐
│                        Test Layer                        │
│          ahb_base_test / ahb_wr_rd_test / ...            │
└────────────────────────┬─────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────┐
│                     Environment (ahb_env)                │
│                                                          │
│  ┌─────────────────────┐   ┌──────────────────────────┐  │
│  │   Master Agent      │   │    Slave Agent           │  │
│  │  ┌───────────────┐  │   │  ┌────────────────────┐  │  │
│  │  │  Sequencer    │  │   │  │    Responder       │  │  │
│  │  │  (ahb_sqr)    │  │   │  │  (ahb_responder)   │  │  │
│  │  └──────┬────────┘  │   │  └────────────────────┘  │  │
│  │         │ sequences │   │  ┌────────────────────┐  │  │
│  │  ┌──────▼────────┐  │   │  │    Monitor         │  │  │
│  │  │    Driver     │  │   │  │    (ahb_mon)       │  │  │
│  │  │   (ahb_drv)   │  │   │  └─────────┬──────────┘  │  │
│  │  └───────────────┘  │   └────────────┼─────────────┘  │
│  │  ┌───────────────┐  │                │                 │
│  │  │    Monitor    │  │                │                 │
│  │  │   (ahb_mon)   │  │                │                 │
│  │  └──────┬────────┘  │                │                 │
│  │  ┌──────▼────────┐  │                │                 │
│  │  │   Coverage    │  │                │                 │
│  │  │  (ahb_cov)    │  │                │                 │
│  │  └───────────────┘  │                │                 │
│  └──────────┬──────────┘                │                 │
│             │                           │                 │
│  ┌──────────▼───────────────────────────▼──────────────┐  │
│  │               Scoreboard (ahb_sbd)                  │  │
│  └─────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────┘
                         │
┌────────────────────────▼─────────────────────────────────┐
│              DUT Interface (ahb_intf / arb_intf)         │
└──────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
AHB_UVC_WORKING/
│
├── COMMON/                  # Shared types, interfaces, and base classes
│   ├── ahb_common.sv        # Enums, macros, and shared counters
│   ├── ahb_intf.sv          # AHB bus interface (clocking blocks)
│   ├── arb_intf.sv          # Arbiter interface
│   ├── ahb_tx.sv            # AHB transaction (sequence item)
│   ├── ahb_mon.sv           # Bus monitor
│   └── ahb_sbd.sv           # Scoreboard
│
├── MASTER/                  # Master-side UVC components
│   ├── ahb_drv.sv           # AHB bus driver
│   ├── ahb_sqr.sv           # Sequencer
│   ├── ahb_magent.sv        # Master agent
│   └── ahb_cov.sv           # Functional coverage collector
│
├── SLAVE/
│   ├── ahb_responder.sv     # Slave responder (handles incoming requests)
│   └── ahb_sagent.sv        # Slave agent
│
├── TOP/                     # Testbench top-level and test library
│   ├── top.sv               # Top-level module (DUT instantiation + UVM kickoff)
│   ├── ahb_env.sv           # UVM environment
│   ├── ahb_seq_lib.sv       # Sequence library (write/read sequences)
│   ├── test_lib.sv          # Test classes
│   └── ahb_assertion.sv     # SVA protocol assertions
│
└── SIM/                     # Simulation scripts
    ├── run.do               # Compilation and simulation script (QuestaSim)
    └── wave.do              # Waveform setup script
```

---

## File Descriptions

### `COMMON/ahb_common.sv`
Defines the core **enumerated types** used throughout the UVC:
- `burst_t` — AHB burst types: `SINGLE`, `INCR`, `WRAP4`, `INCR4`, `WRAP8`, `INCR8`, `WRAP16`, `INCR16`
- `trans_t` — Transfer types: `IDLE`, `BUSY`, `NONSEQ`, `SEQ`
- `error_t` — Response codes: `OKAY`, `ERROR`, `RETRY`, `SPLIT`

Also defines convenience macros (`NEW_COMP`, `NEW_OBJ`) and the `ahb_common` class which holds global scoreboard counters (`total_tx`, `num_matches`, `num_mismatches`).

---

### `COMMON/ahb_intf.sv`
The **SystemVerilog interface** for the AHB bus. It defines:
- All AHB signals (`haddr`, `hwdata`, `hrdata`, `htrans`, `hburst`, `hsize`, `hwrite`, `hreadyout`, `hresp`, etc.)
- Three **clocking blocks** — `master_cb`, `slave_cb`, and `mon_cb` — each with appropriate input/output directions
- Three **modports** — `master_mp`, `slave_mp`, `mon_mp` — to connect the right clocking block to the right component

---

### `COMMON/ahb_tx.sv`
The **AHB transaction class** (`ahb_tx`), which extends `uvm_sequence_item`. This is the data object passed between the sequencer, driver, and monitor.

Key fields:
| Field | Description |
|-------|-------------|
| `addr` | 32-bit transfer address |
| `dataQ[$]` | Queue of 32-bit data beats |
| `wr_rd` | Direction: `1` = write, `0` = read |
| `burst` | Burst type (from `burst_t` enum) |
| `size` | Transfer size (bytes per beat: `2**size`) |
| `len` | Number of beats in the burst |
| `resp` | Slave response code |

Built-in **constraints** ensure legal AHB behavior:
- Burst length must match the burst type (SINGLE→1, WRAP4/INCR4→4, etc.)
- Address must be naturally aligned (`addr % (2**size) == 0`)
- Default burst is `INCR4`, default size is 2 (4 bytes/beat)

---

### `COMMON/ahb_mon.sv`
The **bus monitor** passively observes the AHB interface and reconstructs complete transactions by tracking the two-phase (address → data) AHB pipeline. It implements a state machine based on `htrans` transitions and writes completed transactions to a UVM analysis port (`ap_port`).

---

### `COMMON/ahb_sbd.sv`
The **scoreboard** connects to both the master and slave monitors via separate analysis imp ports. It queues transactions from both sides and compares them using UVM's built-in `compare()` method, incrementing match or mismatch counters in `ahb_common`.

---

### `MASTER/ahb_drv.sv`
The **AHB master driver** pulls transactions from the sequencer and drives the physical AHB bus signals. It implements the full AHB transaction flow:
1. **Arbitration phase** — asserts `hbusreq`, waits for `hgrant`
2. **Address phase** — drives address, burst type, size, and `htrans = NONSEQ/SEQ`
3. **Data phase** — drives `hwdata` (write) or captures `hrdata` (read), checks `hreadyout`

Pipelining is handled by forking the data phase of beat N with the address phase of beat N+1.

---

### `MASTER/ahb_cov.sv`
A **functional coverage collector** implemented as a `uvm_subscriber`. It samples a covergroup (`ahb_cg`) on every transaction written to it, covering:
- Write vs. Read (`WR_RD_CP`)
- All burst types (`BURST_CP`)
- All transfer sizes (`SIZE_CP`)

---

### `MASTER/ahb_magent.sv`
The **master agent** instantiates and connects the driver, sequencer, monitor, and coverage collector. The monitor's analysis port feeds directly into the coverage collector.

---

### `SLAVE/ahb_responder.sv`
The **slave responder** monitors the AHB interface for incoming requests and drives back `hrdata`, `hresp`, and `hreadyout` responses. It acts as a simple memory model for the slave side.

---

### `SLAVE/ahb_sagent.sv`
The **slave agent** instantiates the responder and a monitor. The monitor's analysis port feeds into the scoreboard's slave-side input.

---

### `TOP/ahb_env.sv`
The **UVM environment** that instantiates the master agent, slave agent, and scoreboard, then wires the monitors' analysis ports to the scoreboard.

---

### `TOP/ahb_seq_lib.sv`
Contains the **sequence library**:

| Sequence | Description |
|----------|-------------|
| `ahb_base_seq` | Base sequence — handles phase objection raising/dropping |
| `ahb_wr_rd_seq` | Writes 1 transaction then reads back from the same address |
| `ahb_mult_wr_rd_seq` | Performs N writes followed by N reads (N set via resource DB) |

---

### `TOP/test_lib.sv`
Contains the **test classes**:

| Test | Description |
|------|-------------|
| `ahb_base_test` | Base test — builds the environment, reports pass/fail |
| `ahb_wr_rd_test` | Runs `ahb_wr_rd_seq` (1 write + 1 read) |
| `ahb_wr_rd_build_phase_test` | Same as above but uses config DB to set the default sequence |
| `ahb_mult_wr_rd_test` | Runs `ahb_mult_wr_rd_seq` with 5 writes + 5 reads |

---

### `TOP/ahb_assertion.sv`
Contains **SystemVerilog Assertions (SVA)**:

| Assertion | Description |
|-----------|-------------|
| `AHB_HANDSHAKE_PROP` | After a NONSEQ/SEQ transfer starts, `hreadyout` must go high within 5 clock cycles |
| `AHB_HWDATA_VALID_PROP` | On the cycle after a write address phase, `hwdata` must not be unknown (X/Z) |

---

### `TOP/top.sv`
The **top-level simulation module**. It:
- Instantiates the AHB and arbiter interfaces
- Generates the clock (10ns period) and applies reset
- Sets up virtual interface handles in the UVM resource database
- Instantiates the assertion checker
- Calls `run_test()` to start the UVM phase mechanism

---

## Key Features

- ✅ Full UVM-compliant testbench (agents, sequences, scoreboard, coverage)
- ✅ Pipelined AHB address/data phase handling
- ✅ Support for all AHB burst types (SINGLE, INCR, WRAP4/8/16, INCR4/8/16)
- ✅ Constrained-random transaction generation with legal AHB constraints
- ✅ Write-then-read-back scoreboard checking
- ✅ Functional coverage across burst type, transfer size, and direction
- ✅ SVA protocol checker for handshake and data validity
- ✅ Arbitration interface support (multi-master ready)
- ✅ QuestaSim-ready simulation scripts

---

## AHB Signal Reference

| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| `hclk` | 1 | Input | Bus clock |
| `hrst` | 1 | Input | Active-high reset |
| `haddr` | 32 | Master→Slave | Transfer address |
| `htrans` | 2 | Master→Slave | Transfer type (IDLE/BUSY/NONSEQ/SEQ) |
| `hburst` | 3 | Master→Slave | Burst type |
| `hsize` | 3 | Master→Slave | Transfer size |
| `hwrite` | 1 | Master→Slave | Direction: 1=write, 0=read |
| `hwdata` | 32 | Master→Slave | Write data |
| `hrdata` | 32 | Slave→Master | Read data |
| `hreadyout` | 1 | Slave→Master | Slave ready (1=transfer complete) |
| `hresp` | 2 | Slave→Master | Transfer response (OKAY/ERROR/RETRY/SPLIT) |
| `hprot` | 7 | Master→Slave | Protection control |
| `hexcl` | 1 | Master→Slave | Exclusive transfer |
| `hexokay` | 1 | Slave→Master | Exclusive okay |
| `hnonsec` | 1 | Master→Slave | Non-secure transfer |

---

## Supported Transfer Types

| `htrans` | Value | Meaning |
|----------|-------|---------|
| `IDLE` | `2'b00` | No transfer requested |
| `BUSY` | `2'b01` | Master inserts wait cycles in a burst |
| `NONSEQ` | `2'b10` | First beat of a transfer or single transfer |
| `SEQ` | `2'b11` | Subsequent beats of a burst |

---

## How to Run

This project uses **QuestaSim (ModelSim)**. Open QuestaSim, navigate to the `SIM/` directory, and source the run script:

```tcl
cd AHB_UVC_WORKING/SIM
do run.do
```

The `run.do` script will:
1. Compile all SystemVerilog files with the correct include paths
2. Launch simulation with the default test (`ahb_mult_wr_rd_test`)
3. Load the waveform configuration from `wave.do`
4. Run the simulation to completion

To run a different test, modify the `+UVM_TESTNAME` plusarg in `run.do`:

```tcl
vsim ... +UVM_TESTNAME=ahb_wr_rd_test ...
```

---

## Available Tests

| Test Name | Command | Description |
|-----------|---------|-------------|
| `ahb_base_test` | `+UVM_TESTNAME=ahb_base_test` | Environment build only, no sequences run |
| `ahb_wr_rd_test` | `+UVM_TESTNAME=ahb_wr_rd_test` | 1 write + 1 read back |
| `ahb_wr_rd_build_phase_test` | `+UVM_TESTNAME=ahb_wr_rd_build_phase_test` | Same as above, sequence set via config DB |
| `ahb_mult_wr_rd_test` | `+UVM_TESTNAME=ahb_mult_wr_rd_test` | 5 writes + 5 reads (default) |

---

## Scoreboard and Checking

The scoreboard (`ahb_sbd`) receives transactions independently from the master-side monitor and slave-side monitor. For every completed transaction:

- Both sides are compared using UVM's `compare()` method
- A match increments `ahb_common::num_matches`
- A mismatch increments `ahb_common::num_mismatches`

At the end of simulation, `ahb_base_test::report_phase` checks that:
- `total_tx == num_matches` (every expected transaction passed)
- `num_mismatches == 0`

If both conditions are met, the test is reported as **PASSING**. Otherwise, a UVM error is raised.

---

## Coverage

The `ahb_cov` class collects functional coverage using a covergroup that samples on every transaction. The coverpoints are:

- **`WR_RD_CP`** — Write vs. Read direction (ensures both directions are exercised)
- **`BURST_CP`** — All 8 burst type values (SINGLE through INCR16)
- **`SIZE_CP`** — All transfer sizes

Coverage is sampled automatically as the master monitor writes transactions to the coverage collector.

---

## Assertions

Two SVA properties are checked in real time during simulation:

**1. AHB Handshake** (`AHB_HANDSHAKE_PROP`)
> After a NONSEQ or SEQ transfer begins, the slave must assert `hreadyout` within 5 clock cycles. This catches stalled slaves or bus hang conditions.

**2. Write Data Valid** (`AHB_HWDATA_VALID_PROP`)
> One clock cycle after a write address phase, `hwdata` must not contain unknown values (X or Z). This catches undriven data buses.

---

## Prerequisites

| Tool | Version | Notes |
|------|---------|-------|
| QuestaSim / ModelSim | 10.6b or later | Used for compilation and simulation |
| UVM Library | 1.1d | Included via `+incdir` pointing to the UVM install |
| SystemVerilog | IEEE 1800-2012 | Required for clocking blocks, SVA, and constrained random |

Make sure the UVM library path in `run.do` (`-sv_lib`) points to your local QuestaSim UVM DPI library.

