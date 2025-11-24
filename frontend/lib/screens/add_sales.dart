import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../services/pdf_service.dart';
import 'package:printing/printing.dart';

// Searchable Dropdown Widget
class SearchableDropdown extends StatefulWidget {
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final Function(String?) onChanged;
  final String? Function(String?)? validator;

  const SearchableDropdown({
    Key? key,
    this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.validator,
  }) : super(key: key);

  @override
  State<SearchableDropdown> createState() => _SearchableDropdownState();
}

class _SearchableDropdownState extends State<SearchableDropdown> {
  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchDialog(
        items: widget.items,
        onSelected: (value) {
          widget.onChanged(value);
          Navigator.pop(context);
        },
        currentValue: widget.value,
        hint: widget.hint,
      ),
    );
  }

  String _getDisplayText() {
    if (widget.value == null) return widget.hint;
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => DropdownMenuItem(value: widget.value, child: Text(widget.hint)),
    );
    return (selectedItem.child as Text).data ?? widget.hint;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _showSearchDialog,
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          isDense: true,
          suffixIcon: const Icon(Icons.arrow_drop_down),
          errorText: widget.validator != null ? widget.validator!(widget.value) : null,
        ),
        child: Text(
          _getDisplayText(),
          style: TextStyle(
            color: widget.value == null ? Colors.grey[600] : Colors.black,
          ),
        ),
      ),
    );
  }
}

class _SearchDialog extends StatefulWidget {
  final List<DropdownMenuItem<String>> items;
  final Function(String?) onSelected;
  final String? currentValue;
  final String hint;

  const _SearchDialog({
    required this.items,
    required this.onSelected,
    this.currentValue,
    required this.hint,
  });

  @override
  State<_SearchDialog> createState() => _SearchDialogState();
}

class _SearchDialogState extends State<_SearchDialog> {
  late List<DropdownMenuItem<String>> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          final text = (item.child as Text).data ?? '';
          return text.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.hint,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Cari...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _filterItems,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tidak ada hasil',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = item.value == widget.currentValue;
                        return ListTile(
                          title: item.child,
                          selected: isSelected,
                          selectedTileColor: AppColors.mainColor.withOpacity(0.1),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check,
                                  color: AppColors.mainColor,
                                )
                              : null,
                          onTap: () => widget.onSelected(item.value),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

class SaleItem {
  String? brandId;
  String? barangId;
  String? gudangId;
  String? lantaiId;
  int amount;
  int value;
  int availableStock;
  
  SaleItem({
    this.brandId,
    this.barangId,
    this.gudangId,
    this.lantaiId,
    this.amount = 0,
    this.value = 0,
    this.availableStock = 0,
  });
}

class AddSales extends StatefulWidget {
  const AddSales({super.key});

  @override
  State<AddSales> createState() => _AddSalesState();
}

class _AddSalesState extends State<AddSales> {
  final DataController dataController = Get.find<DataController>();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for sales info
  final TextEditingController _dateController = TextEditingController();
  
  // Sales selections
  String? _selectedCustomerId;
  String _selectedPayment = '1'; // Default to Tunai
  int _selectedStatus = 1; // Default to Selesai
  
  // Multiple sale items
  List<SaleItem> _saleItems = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
    // Set current date as default
    final now = DateTime.now();
    _dateController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    // Add first item
    _addNewItem();
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  void _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        dataController.getData(), // Brands
        dataController.getBarangData(),
        dataController.getGudangData(),
        dataController.getCustomerData(),
      ]);
    } catch (e) {
      print('Debug: Error in _initializeData: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Get available stock for a specific barang in a specific gudang and lantai
  Future<int> _getAvailableStock(String barangId, String gudangId, String? lantaiId) async {
    try {
      if (lantaiId == null || lantaiId.isEmpty) {
        // If no lantai specified, return 0 (require lantai selection)
        return 0;
      }
      // Call the new API endpoint to get stock for specific barang, gudang, and lantai
      final stock = await dataController.getStockForBarangGudangLantai(barangId, gudangId, lantaiId);
      return stock;
    } catch (e) {
      print('Debug: Error getting stock: $e');
      return 0;
    }
  }

  // Update item's available stock when barang, gudang, or lantai changes
  void _updateItemStock(SaleItem item) async {
    if (item.barangId != null && item.gudangId != null && item.lantaiId != null) {
      // Set to -1 to indicate loading
      setState(() {
        item.availableStock = -1;
      });
      
      final stock = await _getAvailableStock(item.barangId!, item.gudangId!, item.lantaiId);
      setState(() {
        item.availableStock = stock;
      });
    }
  }

  void _addNewItem() {
    setState(() {
      _saleItems.add(SaleItem());
    });
  }

  void _removeItem(int index) {
    if (_saleItems.length > 1) {
      setState(() {
        _saleItems.removeAt(index);
      });
    }
  }

  List<dynamic> _getFilteredBarangForBrand(String? brandId) {
    if (brandId == null) return [];
    
    final selectedBrand = dataController.myData.firstWhere(
      (brand) => brand['brand_id'] == brandId,
      orElse: () => null,
    );
    
    if (selectedBrand == null) return [];
    
    final brandName = selectedBrand['brand_nama'];
    
    return dataController.barangData.where((barang) {
      return barang['brand_id'] == brandId || barang['brand_nama'] == brandName;
    }).toList();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_dateController.text) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _dateController.text = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  int _calculateTotal() {
    int total = 0;
    for (var item in _saleItems) {
      total += item.amount * item.value;
    }
    return total;
  }

  void _createSales() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCustomerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih customer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate all items
    for (int i = 0; i < _saleItems.length; i++) {
      final item = _saleItems[i];
      if (item.barangId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pilih barang untuk item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (item.gudangId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pilih gudang untuk item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (item.amount <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Masukkan jumlah untuk item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (item.value <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Masukkan harga jual untuk item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      if (item.lantaiId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pilih lantai untuk item ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Check stock availability
      final availableStock = await _getAvailableStock(item.barangId!, item.gudangId!, item.lantaiId);
      if (availableStock < item.amount) {
        final barangName = dataController.barangData.firstWhere(
          (b) => b['barang_id'] == item.barangId,
          orElse: () => {'barang_nama': 'Unknown'},
        )['barang_nama'];
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stok tidak mencukupi untuk item ${i + 1} ($barangName). Tersedia: $availableStock, Diminta: ${item.amount}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare sales data
      final salesData = {
        "customer_id": _selectedCustomerId,
        "sales_payment": _selectedPayment,
        "sales_date": _dateController.text,
        "sales_status": _selectedStatus,
        "sale_items": _saleItems.map((item) => {
          "barang_id": item.barangId,
          "gudang_id": item.gudangId,
          "lantai_id": item.lantaiId,
          "sale_items_amount": item.amount,
          "sale_value": item.value,
        }).toList(),
      };

      bool success = await dataController.createCombinedSales(salesData);
      
      if (success) {
        // Refresh sales data
        await dataController.getSalesData();
        
        // Get the newly created sales data (it should be the first one after refresh since we sort by date DESC)
        if (dataController.salesData.isNotEmpty) {
          final newSalesData = dataController.salesData.first;
          
          // Get full sales detail with items
          await dataController.getSingleSalesData(newSalesData['sales_id']);
          final fullSalesData = dataController.singleSalesData;
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil membuat penjualan dengan ${_saleItems.length} item'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          
          // Show PDF options dialog
          _showPdfOptionsDialog(fullSalesData);
        } else {
          _resetForm();
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuat penjualan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _resetForm() {
    setState(() {
      _dateController.clear();
      _selectedCustomerId = null;
      _selectedPayment = '1';
      _selectedStatus = 1;
      _saleItems.clear();
      _addNewItem();
      
      final now = DateTime.now();
      _dateController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    });
  }

  String _formatCurrency(int value) {
    return 'Rp ${value.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}';
  }

  void _showPdfOptionsDialog(Map<String, dynamic> createdSalesData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Penjualan Berhasil Dibuat!',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah Anda ingin membuat dokumen?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Dokumen akan disimpan/dibagikan sebagai file PDF',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetForm();
            },
            child: const Text('Lewati'),
          ),
          OutlinedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _generateReceipt(createdSalesData);
              _resetForm();
            },
            icon: const Icon(Icons.receipt, size: 18),
            label: const Text('Struk'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _generateInvoice(createdSalesData);
              _resetForm();
            },
            icon: const Icon(Icons.description, size: 18),
            label: const Text('Invoice'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.mainColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16, left: 16),
      ),
    );
  }

  Future<void> _generateInvoice(Map<String, dynamic> salesData) async {
    try {
      // Show loading
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Membuat Invoice...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final pdfBytes = await PdfService.generateInvoice(salesData);
      final filename = PdfService.generateInvoiceFilename(salesData);
      
      // Close loading
      Get.back();

      // Use layoutPdf which works better on mobile (opens share/print dialog)
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: filename,
      );
    } catch (e) {
      Get.back(); // Close loading if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat invoice: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _generateReceipt(Map<String, dynamic> salesData) async {
    try {
      // Show loading
      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Membuat Struk...'),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final pdfBytes = await PdfService.generateReceipt(salesData);
      final filename = PdfService.generateReceiptFilename(salesData);
      
      // Close loading
      Get.back();

      // Use layoutPdf which works better on mobile (opens share/print dialog)
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
        name: filename,
      );
    } catch (e) {
      Get.back(); // Close loading if open
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat struk: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Nota",
            ),
            Expanded(
              child: Container(
                width: double.maxFinite,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: _isLoading
                    ? Center(
                        child: SpinKitCircle(
                          color: AppColors.mainColor,
                          size: 50.0,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Buat Penjualan Baru',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Anda dapat menambahkan beberapa barang sekaligus',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Customer Selection
                              const Text(
                                'Customer',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SearchableDropdown(
                                value: _selectedCustomerId,
                                hint: 'Pilih Customer',
                                items: dataController.customerData.map((customer) {
                                  return DropdownMenuItem<String>(
                                    value: customer['customer_id'],
                                    child: Text(customer['customer_nama'] ?? ''),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedCustomerId = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Pilih customer';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Date Field
                              const Text(
                                'Tanggal Penjualan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _dateController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  hintText: 'Pilih tanggal',
                                  suffixIcon: const Icon(Icons.calendar_today),
                                ),
                                onTap: _selectDate,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Pilih tanggal';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Payment Type
                              const Text(
                                'Jenis Pembayaran',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedPayment,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(value: '1', child: Text('Tunai')),
                                  DropdownMenuItem(value: '2', child: Text('Transfer')),
                                  DropdownMenuItem(value: '3', child: Text('Kredit')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedPayment = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Status
                              const Text(
                                'Status Penjualan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedStatus,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 1, child: Text('Selesai')),
                                  DropdownMenuItem(value: 2, child: Text('Diproses')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedStatus = value!;
                                  });
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              // Items header with add button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Barang yang Dijual',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _addNewItem,
                                    icon: const Icon(Icons.add, size: 18),
                                    label: const Text('Tambah Item'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.mainColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              // Sale items list
                              ..._saleItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return _buildSaleItemCard(index, item);
                              }).toList(),
                              
                              // Total display
                              if (_saleItems.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.blue, width: 2),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total Penjualan:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _formatCurrency(_calculateTotal()),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              
                              const SizedBox(height: 32),
                              
                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _resetForm,
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text('Reset Form'),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _createSales,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.mainColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                              ),
                                            )
                                          : const Text('Buat Penjualan'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaleItemCard(int index, SaleItem item) {
    final filteredBarang = _getFilteredBarangForBrand(item.brandId);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Item ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_saleItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeItem(index),
                    tooltip: 'Hapus item',
                  ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 12),
            
            // Brand Dropdown (for filtering only)
            const Text(
              'Pabrik/Brand (untuk filter)',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            SearchableDropdown(
              value: item.brandId,
              hint: 'Pilih Brand',
              items: dataController.myData.map((brand) {
                return DropdownMenuItem<String>(
                  value: brand['brand_id'],
                  child: Text(brand['brand_nama'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  item.brandId = value;
                  item.barangId = null; // Reset barang when brand changes
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Barang Dropdown
            const Text(
              'Barang',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            SearchableDropdown(
              value: item.barangId,
              hint: 'Pilih Barang',
              items: filteredBarang.map((barang) {
                return DropdownMenuItem<String>(
                  value: barang['barang_id'],
                  child: Text(barang['barang_nama'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  item.barangId = value;
                  item.availableStock = 0; // Reset stock until gudang is selected
                });
                if (item.gudangId != null) {
                  _updateItemStock(item);
                }
              },
            ),
            const SizedBox(height: 12),
            
            // Gudang Dropdown
            const Text(
              'Gudang',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            SearchableDropdown(
              value: item.gudangId,
              hint: 'Pilih Gudang',
              items: dataController.gudangData.map((gudang) {
                return DropdownMenuItem<String>(
                  value: gudang['gudang_id'],
                  child: Text(gudang['gudang_nama'] ?? ''),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  item.gudangId = value;
                  item.lantaiId = null; // Reset lantai when gudang changes
                  item.availableStock = 0; // Reset until lantai is selected
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Lantai Dropdown
            const Text(
              'Lantai',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            FutureBuilder<List<dynamic>>(
              future: item.gudangId != null ? dataController.getFloorsByGudang(item.gudangId!) : null,
              builder: (context, snapshot) {
                if (item.gudangId == null) {
                  return AbsorbPointer(
                    absorbing: true,
                    child: Opacity(
                      opacity: 0.5,
                      child: SearchableDropdown(
                        value: null,
                        hint: 'Pilih Gudang terlebih dahulu',
                        items: const [],
                        onChanged: (value) {},
                      ),
                    ),
                  );
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Tidak ada lantai untuk gudang ini',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  );
                }
                
                final floors = snapshot.data!;
                return SearchableDropdown(
                  value: item.lantaiId,
                  hint: 'Pilih Lantai',
                  items: floors.map((floor) {
                    return DropdownMenuItem<String>(
                      value: floor['lantai_id'],
                      child: Text(floor['lantai_nama'] ?? ''),
                    );
                  }).toList(),
                  onChanged: (value) async {
                    setState(() {
                      item.lantaiId = value;
                      item.availableStock = 0; // Reset until stock is loaded
                    });
                    if (item.barangId != null && item.gudangId != null) {
                      _updateItemStock(item);
                    }
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            
            // Amount and Value in a row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Jumlah',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: item.amount > item.availableStock && item.availableStock >= 0
                                  ? Colors.red
                                  : Colors.grey,
                              width: item.amount > item.availableStock && item.availableStock >= 0 ? 2 : 1,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                          hintText: '0',
                          errorText: item.amount > item.availableStock && item.availableStock >= 0
                              ? 'Melebihi stok!'
                              : null,
                        ),
                        onChanged: (value) {
                          setState(() {
                            item.amount = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                      // Stock availability display moved here
                      if (item.barangId != null && item.gudangId != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.availableStock == -1 
                                ? Colors.grey.withOpacity(0.1)
                                : item.availableStock > 0 
                                    ? Colors.blue.withOpacity(0.1) 
                                    : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: item.availableStock == -1
                                  ? Colors.grey
                                  : item.availableStock > 0 
                                      ? Colors.blue 
                                      : Colors.red,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (item.availableStock == -1)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Icon(
                                  item.availableStock > 0 ? Icons.check_circle : Icons.warning,
                                  size: 16,
                                  color: item.availableStock > 0 ? Colors.blue : Colors.red,
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.availableStock == -1 
                                      ? 'Memuat stok...' 
                                      : 'Stok: ${item.availableStock}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: item.availableStock == -1
                                        ? Colors.grey
                                        : item.availableStock > 0 
                                            ? Colors.blue 
                                            : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Harga Jual (Rp)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          isDense: true,
                          hintText: '0',
                        ),
                        onChanged: (value) {
                          setState(() {
                            item.value = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                          });
                        },
                      ),
                      // Harga Jual Referensi from database
                      if (item.barangId != null) ...[
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final selectedBarang = dataController.barangData.firstWhere(
                              (b) => b['barang_id'] == item.barangId,
                              orElse: () => null,
                            );
                            
                            if (selectedBarang == null) return const SizedBox.shrink();
                            
                            final hargaJual = selectedBarang['barang_harga_jual'] ?? 0;
                            
                            return Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Ref: ${_formatCurrency(hargaJual)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            // Subtotal display
            if (item.amount > 0 && item.value > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subtotal:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatCurrency(item.amount * item.value),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
