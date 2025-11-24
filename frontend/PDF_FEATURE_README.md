# PDF Invoice and Receipt Generation Feature

## Overview
After successfully creating a sales record, users now have the option to generate and download PDF documents (Invoice or Receipt).

## New Features

### 1. PDF Options Dialog
After creating a sales record, a dialog appears with three options:
- **Lewati (Skip)** - Continue without generating any document
- **Struk (Receipt)** - Generate a compact sales receipt (A5 format)
- **Invoice** - Generate a detailed sales invoice (A4 format)

### 2. Invoice PDF (Detailed)
**Format:** A4
**Contains:**
- Company header with name, address, and phone
- Invoice number and date
- Customer information (name, contact, address)
- Payment type and status
- Detailed items table with:
  - Item number
  - Product name
  - Warehouse
  - Quantity
  - Unit price
  - Subtotal
- Grand total
- Signature sections for receiver and company representative

### 3. Receipt PDF (Compact)
**Format:** A5
**Contains:**
- Company header (centered)
- Receipt number and date
- Customer name
- Payment type
- List of items with quantity and prices
- Grand total
- "Terima Kasih" footer

## How It Works

1. User fills out the sales form and clicks "Buat Penjualan"
2. System validates and creates the sales record
3. Success dialog appears with PDF generation options
4. User can:
   - Skip document generation
   - Generate a receipt (compact)
   - Generate an invoice (detailed)
5. Selected PDF is generated and can be:
   - Shared (on mobile devices)
   - Printed (on desktop/web)
   - Saved to device

## Technical Implementation

### New Dependencies
```yaml
pdf: ^3.10.8          # PDF document generation
printing: ^5.12.0     # PDF printing and sharing
path_provider: ^2.1.2 # File system access
```

### New Files
- `lib/services/pdf_service.dart` - PDF generation service

### Modified Files
- `lib/screens/add_sales.dart` - Added PDF dialog and generation functions
- `pubspec.yaml` - Added PDF dependencies

## User Experience Flow

```
Create Sales → Success → Dialog Appears
                              ↓
                    ┌─────────┼─────────┐
                    ↓         ↓         ↓
                  Skip    Generate    Generate
                           Receipt    Invoice
                    ↓         ↓         ↓
                  Done   Share/Save  Share/Save
```

## Customization

To customize company information in the PDF:
1. Open `lib/services/pdf_service.dart`
2. Find the text sections:
   - "Nama Perusahaan"
   - "Alamat Perusahaan"
   - "Telp: (021) 1234567"
3. Replace with actual company details

## Notes

- PDFs are generated with customer contact and address (if available)
- Invoice includes detailed item breakdown with warehouse information
- Receipt is more compact for quick reference
- Both documents are professionally formatted
- Files are named: `Invoice_[sales_id].pdf` or `Struk_[sales_id].pdf`
- On mobile: PDF opens in share dialog
- On desktop/web: PDF opens in print preview

## Future Enhancements

Possible improvements:
- Add company logo to PDFs
- Customize PDF styling/branding
- Add QR code for invoice verification
- Email PDF directly to customer
- Save PDF history
- Multiple language support
