# Frontend Requirements

This document outlines frontend requirements for displaying component fields based on component categories.

## Component Field Display Rules

### MOSFET Fields (Show only when category_id = 6)

The following MOSFET-related fields should **only be displayed** on the frontend when `category_id === 6` (Mosfet category):

- `rds_on` - On-resistance, e.g. "22mΩ @ 4.5V"
- `vgs_max` - Max gate-source voltage, e.g. "±20V"
- `vgs_th` - Gate threshold voltage, e.g. "1–3V"
- `qg` - Gate charge (nC)
- `ciss` - Input capacitance (pF)
- `switching_type` - Switching type

**Implementation:**
```javascript
// Example: Only show MOSFET fields if category_id is 6
if (component.category_id === 6) {
  // Display MOSFET fields: rds_on, vgs_max, vgs_th, qg, ciss, switching_type
}
```

### Diode Fields (Show only when category_id is 7, 8, or 9)

The following Diode-related fields should **only be displayed** on the frontend when `category_id` is one of:
- `category_id === 7` (Switching / Signal Diodes)
- `category_id === 8` (Dual / High-Speed Diodes)
- `category_id === 9` (Schottky Diodes)

Fields to show:
- `vf` - Forward voltage @ IF
- `trr` - Reverse recovery time
- `cj` - Junction capacitance
- `diode_type` - Diode type
- `internal_config` - Internal configuration (for dual diodes, shows "Series", "Common Cathode", etc.)

**Implementation:**
```javascript
// Example: Only show Diode fields if category_id is 7, 8, or 9
if ([7, 8, 9].includes(component.category_id)) {
  // Display Diode fields: vf, trr, cj, diode_type, internal_config
}
```

### Voltage Regulator Fields (Show only when category_id = 10)

The following Voltage Regulator-related fields should **only be displayed** on the frontend when `category_id === 10` (Zener / Reference / Regulator ICs):

- `v_in_max` - Maximum input voltage, e.g. "36V", "35V"
- `v_out` - Output voltage, e.g. "3.3V", "5V", "2.5V adjustable"
- `i_out_max` - Maximum output current, e.g. "1A", "500mA", "100mA"
- `accuracy` - Voltage accuracy, e.g. "±1%", "±5%"
- `reg_type` - Regulator type, e.g. "Linear", "Switching", "Voltage Reference"

**Implementation:**
```javascript
// Example: Only show Voltage Regulator fields if category_id is 10
if (component.category_id === 10) {
  // Display Voltage Regulator fields: v_in_max, v_out, i_out_max, accuracy, reg_type
}
```

## Category ID Reference

| Category ID | Category Name | Show Specific Fields |
|-------------|---------------|---------------------|
| 1 | Transistor | Standard fields only (v_max, i_max, power_max, gain_min, gain_max) |
| 2 | IC | Standard fields + additional_characteristics |
| 3 | Resistor | Standard fields + additional_characteristics |
| 4 | Capacitor | Standard fields + additional_characteristics |
| 5 | Diode | Standard fields + additional_characteristics |
| 6 | Mosfet | **MOSFET fields** (rds_on, vgs_max, vgs_th, qg, ciss, switching_type) |
| 7 | Switching / Signal Diodes | **Diode fields** (vf, trr, cj, diode_type) |
| 8 | Dual / High-Speed Diodes | **Diode fields** (vf, trr, cj, diode_type, internal_config) |
| 9 | Schottky Diodes | **Diode fields** (vf, trr, cj, diode_type, internal_config) |
| 10 | Zener / Reference / Regulator ICs | **Voltage Regulator fields** (v_in_max, v_out, i_out_max, accuracy, reg_type) |
| 11 | Misc / Logic / Special Devices | Standard fields + additional_characteristics |

## General Rules

1. **Always show basic fields** for all components:
   - `id`, `part_number`, `marking`, `category_id`, `category_name`
   - `technology`, `polarity`, `channel`, `package`
   - `v_max`, `i_max`, `power_max`, `gain_min`, `gain_max`
   - `unit_price`, `status`, `notes`
   - `additional_characteristics`
   - Inventory fields: `quantity`, `min_qty`, `location`, `inventory_last_updated`, `total_value`

2. **Conditionally show category-specific fields** based on `category_id`:
   - MOSFET fields: Only for `category_id === 6`
   - Diode fields: Only for `category_id === 7, 8, or 9`
   - Voltage Regulator fields: Only for `category_id === 10`

3. **Hide fields when null**: If a field value is `null`, you can choose to hide it or display it as empty/not applicable.

4. **Form validation**: When creating/editing components:
   - Only validate MOSFET fields if `category_id === 6`
   - Only validate Diode fields if `category_id === 7, 8, or 9`
   - Only validate Voltage Regulator fields if `category_id === 10`

## Example Frontend Implementation

```typescript
// TypeScript/React example
interface Component {
  id: number;
  part_number: string;
  category_id: number;
  // ... other fields
  // MOSFET fields
  rds_on?: string | null;
  vgs_max?: string | null;
  vgs_th?: string | null;
  qg?: string | null;
  ciss?: string | null;
  switching_type?: string | null;
  // Diode fields
  vf?: string | null;
  trr?: string | null;
  cj?: string | null;
  diode_type?: string | null;
  internal_config?: string | null;
  // Voltage Regulator fields
  v_in_max?: string | null;
  v_out?: string | null;
  i_out_max?: string | null;
  accuracy?: string | null;
  reg_type?: string | null;
}

function ComponentForm({ component }: { component: Component }) {
  const showMOSFETFields = component.category_id === 6;
  const showDiodeFields = [7, 8, 9].includes(component.category_id);
  const showRegulatorFields = component.category_id === 10;

  return (
    <form>
      {/* Basic fields - always show */}
      <input name="part_number" value={component.part_number} />
      <input name="v_max" value={component.v_max} />
      {/* ... other basic fields */}

      {/* MOSFET fields - only show if category_id === 6 */}
      {showMOSFETFields && (
        <>
          <input name="rds_on" value={component.rds_on || ''} />
          <input name="vgs_max" value={component.vgs_max || ''} />
          <input name="vgs_th" value={component.vgs_th || ''} />
          <input name="qg" value={component.qg || ''} />
          <input name="ciss" value={component.ciss || ''} />
          <input name="switching_type" value={component.switching_type || ''} />
        </>
      )}

      {/* Diode fields - only show if category_id is 7, 8, or 9 */}
      {showDiodeFields && (
        <>
          <input name="vf" value={component.vf || ''} />
          <input name="trr" value={component.trr || ''} />
          <input name="cj" value={component.cj || ''} />
          <input name="diode_type" value={component.diode_type || ''} />
          <input name="internal_config" value={component.internal_config || ''} />
        </>
      )}

      {/* Voltage Regulator fields - only show if category_id === 10 */}
      {showRegulatorFields && (
        <>
          <input name="v_in_max" value={component.v_in_max || ''} />
          <input name="v_out" value={component.v_out || ''} />
          <input name="i_out_max" value={component.i_out_max || ''} />
          <input name="accuracy" value={component.accuracy || ''} />
          <input name="reg_type" value={component.reg_type || ''} />
        </>
      )}
    </form>
  );
}
```

## Notes

- All component-specific fields are optional and may be `null`
- The API returns all fields for all components, but the frontend should conditionally display them
- When a user changes the `category_id` in a form, show/hide the relevant fields accordingly
- Field labels and placeholders should match the examples provided in the API documentation

