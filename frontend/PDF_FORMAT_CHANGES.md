# PDF Receipt & Invoice Formatting Updates

## Changes Made

### 1. Company Information Updated

**Previous:**
- Nama Perusahaan
- Alamat Perusahaan
- Telp: (021) 1234567

**New:**
- **Victoria Mebel**
- **Jl. Andalas No.38-40**
- **Telp: (0411) 3634028**

Updated in both Invoice and Receipt PDFs.

---

### 2. Receipt Number Format Changed

**Previous:**
- No: SL_0000007 (full ID)

**New:**
- No: 007 (last 3 digits only)

The receipt now only displays the last 3 digits of the sales ID for a cleaner look.

---

### 3. File Naming Convention Updated

#### Receipt Filename Format:
**Previous:** `Struk_SL_0000007.pdf`

**New:** `Struk_CustomerName_YYMMDDXXX.pdf`

**Example:** `Struk_LiaMirwanti_251016007.pdf`

**Breakdown:**
- `Struk_` - Prefix
- `LiaMirwanti` - Customer name (spaces removed)
- `251016` - Date in YYMMDD format (25=year 2025, 10=October, 16=day)
- `007` - Last 3 digits of sales ID
- `.pdf` - Extension

#### Invoice Filename Format:
**Previous:** `Invoice_SL_0000007.pdf`

**New:** `Invoice_CustomerName_YYMMDDXXX.pdf`

**Example:** `Invoice_LiaMirwanti_251016007.pdf`

---

## Implementation Details

### New Helper Functions Added:

1. **`PdfService.generateReceiptFilename(salesData)`**
   - Extracts customer name and removes spaces
   - Extracts last 3 digits from sales_id
   - Formats date as YYMMDD from YYYY-MM-DD
   - Returns: `Struk_CustomerName_YYMMDDXXX.pdf`

2. **`PdfService.generateInvoiceFilename(salesData)`**
   - Same logic as receipt filename
   - Returns: `Invoice_CustomerName_YYMMDDXXX.pdf`

### Date Format Conversion:

Input: `2025-10-16` (YYYY-MM-DD)
Output: `251016` (YYMMDD)

- Year: Last 2 digits (2025 → 25)
- Month: 2 digits (10)
- Day: 2 digits (16)

---

## Example Outputs

### Example 1:
- Customer: Lia Mirwanti
- Date: 2025-10-16
- Sales ID: SL_0000007
- **Receipt Filename:** `Struk_LiaMirwanti_251016007.pdf`
- **Invoice Filename:** `Invoice_LiaMirwanti_251016007.pdf`
- **Receipt No:** 007

### Example 2:
- Customer: Rudi Haryanto
- Date: 2025-10-15
- Sales ID: SL_0000123
- **Receipt Filename:** `Struk_RudiHaryanto_251015123.pdf`
- **Invoice Filename:** `Invoice_RudiHaryanto_251015123.pdf`
- **Receipt No:** 123

### Example 3:
- Customer: John Doe Smith
- Date: 2024-12-31
- Sales ID: SL_0000045
- **Receipt Filename:** `Struk_JohnDoeSmith_241231045.pdf`
- **Invoice Filename:** `Invoice_JohnDoeSmith_241231045.pdf`
- **Receipt No:** 045

---

## Files Modified

1. **`lib/services/pdf_service.dart`**
   - Updated company information in `generateReceipt()`
   - Updated company information in `generateInvoice()`
   - Changed receipt No to show last 3 digits only
   - Added `generateReceiptFilename()` helper function
   - Added `generateInvoiceFilename()` helper function

2. **`lib/screens/add_sales.dart`**
   - Updated `_generateInvoice()` to use new filename generator
   - Updated `_generateReceipt()` to use new filename generator

---

## Benefits

1. **Professional Branding:** Real company name and contact info
2. **Cleaner Receipt:** Short 3-digit number instead of full ID
3. **Organized Files:** Descriptive filenames with customer name and date
4. **Easy Sorting:** YYMMDD format allows chronological file sorting
5. **Unique Names:** Combination of customer + date + ID ensures uniqueness

---

## Testing

To test the changes:
1. Create a new sales record
2. Choose to generate a Receipt or Invoice
3. Check the PDF content shows "Victoria Mebel" and new address/phone
4. Check the Receipt shows only last 3 digits for "No:"
5. Check the filename follows the new format: `Struk_CustomerName_YYMMDDXXX.pdf`

---

## Notes

- Customer names with spaces are concatenated (e.g., "Lia Mirwanti" → "LiaMirwanti")
- If sales_id is shorter than 3 characters, the full ID is used
- Date parsing is safe - if format is unexpected, defaults to "date" placeholder
- The full sales_id is still stored in database, only display format changed
