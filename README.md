# ♻️ Environmental Impact Optimization for Rotational Moulding

This MATLAB project performs **environmental impact optimization** for composite materials used in **rotational moulding**. It analyzes the effect of varying the **abaca fibre content** (0–20%) in a composite made of **Low Density Polyethylene (LDPE), PEMA**, and **Abaca fibre**, and determines the fibre ratio that minimizes environmental impacts across multiple categories.

---
Baris Ördek‬ (1*) & Christian Spreafico (1)

(1) Department of Management Information and Production Engineering, University of Bergamo, Viale Marconi 5, 24044 Dalmine (Bg), Italy. 

(*) baris.ordek@unibg.it

---
## 📌 Key Features

- 🔁 **Multi-category Optimization** for 18 environmental impact categories (e.g., GWP, FFP, PMFP).
- 📊 **Material Impact Modeling** including raw material production, transportation, and energy usage.
- ⚙️ **Energy Calculations** for cooking and rotational phases.
- 🧠 **Smart Allocation** of material fractions with cooking time adaptation.
- 📥 **Excel Export** of final results for post-processing and analysis.

---

## 📁 File Structure

| File                             | Description |
|----------------------------------|-------------|
| `optimize_I_tot.m`              | Main function. Runs the optimization for all impact categories. |
| `objective_fiber.m`             | Objective function for `fmincon` optimization. |
| `compute_all_impacts.m`         | Calculates environmental impacts based on material fractions and energy use. |
| `get_constants.m`               | User input + constants for physical and environmental parameters. |
| `impact_factors.xlsx`           | External database of environmental factors (region-dependent). |
| `optimized_Impacts.xlsx`        | Output file storing results of optimization for each category. |

---

## ⚙️ How It Works

1. User provides process and material inputs via `get_constants()`.
2. For each impact category:
   - The optimizer determines the **fibre ratio** that minimizes the impact per kg.
   - PE and PEMA fractions are derived accordingly.
   - Energy use and mass are calculated.
   - Total and per-kg impacts are computed.
3. Results are stored and exported to an Excel file.

---

## 📥 Setup & Usage

### ✅ Requirements
- MATLAB (R2021a or later recommended)
- Optimization Toolbox
---
### 🔐 License

This project is licensed under the **GNU GPL v3.0**.  
You may freely use, distribute, and modify it under the license terms.

For full license details, see [LICENSE](https://www.gnu.org/licenses/gpl-3.0.en.html).

## 🙋‍♀️ Authors

- **Baris Ördek**
- **Christian Spreafico**  

## 📩 Contact

For academic collaborations or questions, feel free to open an issue or reach out to the authors.

---

### ▶️ Run the Optimization

```matlab
optimize_I_tot
