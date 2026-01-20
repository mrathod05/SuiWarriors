# ⚔️ Sui Warriors — Object-Centric GameFi Demo

A production-style **Sui Move** smart contract demonstrating **object ownership**, **dynamic object composition**, **shared protocol state**, and **realistic testing patterns**.

This project is intentionally designed to showcase how **Sui differs from Aptos and other account-based Move chains**, focusing on object-centric authorization instead of signer-based access.

---

## ✨ What This Demonstrates

- ✅ Sui **object ownership model**
- ✅ **Dynamic Object Fields** (equip / unequip mechanics)
- ✅ **Shared objects** for global protocol state
- ✅ **One-Time Witness (OTW)** for safe initialization
- ✅ Explicit ownership transfers (`public_transfer`)
- ✅ Real-world **transaction-level tests**
- ✅ No imaginary helpers or unsafe shortcuts

---

## 🧠 Core Design Concepts

### Object-Centric Authorization (No `signer`)

In Sui, **authorization is enforced by object ownership**, not by signer parameters.

A function can only be executed if the caller provides:

- The correct objects
- With the correct ownership
- With the correct mutability

This contract relies entirely on those guarantees.

---
