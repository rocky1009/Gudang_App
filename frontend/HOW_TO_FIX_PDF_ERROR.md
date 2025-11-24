# How to Fix the PDF Generation Error

## The Issue
The error "MissingPluginException(No implementation found for method sharePdf on channel net.nfet.printing)" occurs because the printing plugin wasn't properly registered when you hot-reloaded the app.

## Solution: Complete App Restart

### Steps to Fix:

1. **Stop the app completely** (close it on your emulator/device)

2. **In VS Code terminal, run:**
   ```powershell
   flutter clean
   flutter pub get
   ```

3. **Restart the app:**
   ```powershell
   flutter run
   ```

   OR press `Shift + F5` in VS Code to stop and restart

4. **Wait for the app to rebuild completely** - this may take a minute

5. **Try creating a sales record again** and generate the PDF

## What Changed

I've updated the code to use `Printing.layoutPdf()` instead of `Printing.sharePdf()`, which:
- Works more reliably on mobile devices
- Opens a native share/print dialog
- Allows users to:
  - Save to device
  - Print
  - Share via other apps
  - Open in PDF viewer

## Testing After Restart

1. Go to "Tambah Penjualan"
2. Fill in the sales form
3. Click "Buat Penjualan"
4. When the success dialog appears, click "Invoice" or "Struk"
5. A native share/print dialog should open
6. You can save or share the PDF from there

## Note

Hot reload (pressing 'r') or hot restart (pressing 'R') is **NOT enough** for native plugins like the printing package. You must do a complete app restart.
