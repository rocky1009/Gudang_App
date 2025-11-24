import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:proyek_gudang/controllers/data_controller.dart';
import '../widgets/header_widget.dart';
import '../utils/app_colors.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

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

class OrderItem {
  String? brandId;
  String? barangId;
  String? gudangId; // Selected warehouse
  String? lantaiId; // Selected floor
  int amount;
  int availableStock;
  List<Map<String, dynamic>> availableFloors; // Floors available in selected warehouse
  
  OrderItem({
    this.brandId,
    this.barangId,
    this.gudangId,
    this.lantaiId,
    this.amount = 0,
    this.availableStock = 0,
    this.availableFloors = const [],
  });
}

class AddBarangInOut extends StatefulWidget {
  const AddBarangInOut({super.key});

  @override
  State<AddBarangInOut> createState() => _AddBarangInOutState();
}

class _AddBarangInOutState extends State<AddBarangInOut> {
  final DataController dataController = Get.find<DataController>();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for logs info
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  
  // Status selection (0=Pending, 1=Done)
  int _selectedDone = 0; // Default to pending
  
  // Multiple order items (each with its own warehouse)
  List<OrderItem> _orderItems = [];
  
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
    _descController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  void _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Future.wait([
        dataController.getData(),
        dataController.getBarangData(),
        dataController.getGudangData(),
      ]);
    } catch (e) {
      print('Debug: Error in _initializeData: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addNewItem() {
    setState(() {
      _orderItems.add(OrderItem());
    });
  }

  void _removeItem(int index) {
    if (_orderItems.length > 1) {
      setState(() {
        _orderItems.removeAt(index);
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

  void _updateStockForItem(int index) async {
    final item = _orderItems[index];
    if (item.barangId == null || item.lantaiId == null) {
      setState(() {
        item.availableStock = 0;
      });
      return;
    }

    try {
      // Fetch current stock info from the API
      Map<String, dynamic> stockInfo = await dataController.getCurrentStockInfo(item.barangId!);
      
      if (stockInfo.isNotEmpty && stockInfo['current_stocks'] != null) {
        var currentStocks = stockInfo['current_stocks'] as List;
        
        // Find stock for the selected floor
        for (var stock in currentStocks) {
          if (stock['lantai_id'] == item.lantaiId) {
            setState(() {
              item.availableStock = stock['stock_barang'] ?? 0;
            });
            return;
          }
        }
      }
    } catch (e) {
      print('Error fetching stock: $e');
    }

    setState(() {
      item.availableStock = 0;
    });
  }

  void _updateFloorsForGudang(int index) async {
    final item = _orderItems[index];
    if (item.barangId == null || item.gudangId == null) {
      setState(() {
        item.availableFloors = [];
        item.lantaiId = null;
        item.availableStock = 0;
      });
      return;
    }

    try {
      // Fetch current stock info to get floors for this gudang
      Map<String, dynamic> stockInfo = await dataController.getCurrentStockInfo(item.barangId!);
      
      if (stockInfo.isNotEmpty && stockInfo['current_stocks'] != null) {
        var currentStocks = stockInfo['current_stocks'] as List;
        
        // Filter floors by selected gudang
        List<Map<String, dynamic>> floors = currentStocks
            .where((stock) => stock['gudang_id'] == item.gudangId)
            .map<Map<String, dynamic>>((stock) => {
              'lantai_id': stock['lantai_id'],
              'lantai_no': stock['lantai_no'],
              'lantai_nama': stock['lantai_nama'],
              'gudang_nama': stock['gudang_nama'],
              'stock_barang': stock['stock_barang'] ?? 0,
            })
            .toList();
        
        // Sort by lantai_no
        floors.sort((a, b) => (a['lantai_no'] as int).compareTo(b['lantai_no'] as int));
        
        setState(() {
          item.availableFloors = floors;
          item.lantaiId = null; // Reset selected floor
          item.availableStock = 0;
        });
      }
    } catch (e) {
      print('Error fetching floors: $e');
      setState(() {
        item.availableFloors = [];
        item.lantaiId = null;
        item.availableStock = 0;
      });
    }
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

  void _createBatchOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate all items
    for (int i = 0; i < _orderItems.length; i++) {
      final item = _orderItems[i];
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
      if (item.lantaiId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pilih lantai untuk item ${i + 1}'),
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
      if (item.amount > item.availableStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Jumlah item ${i + 1} melebihi stok tersedia (${item.availableStock} unit)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare batch order data for outgoing goods (orders_keluar)
      final batchOrderData = {
        "logs_date": _dateController.text,
        "logs_desc": _descController.text.isEmpty ? "-" : _descController.text,
        "orders_status": _selectedDone, // 0=Pending, 1=Done
        "orders": _orderItems.map((item) => {
          "lantai_id": item.lantaiId, // Send lantai_id instead of gudang_id
          "barang_id": item.barangId,
          "orders_amount": item.amount,
        }).toList(),
      };

      bool success = await dataController.createBatchOrderKeluar(batchOrderData);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil membuat transaksi dengan ${_orderItems.length} item'),
            backgroundColor: Colors.green,
          ),
        );
        
        await Future.wait([
          dataController.getBarangLogs(),
          dataController.getBarangData(),
        ]);
        
        _resetForm();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membuat transaksi'),
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
      _descController.clear();
      _selectedDone = 0;
      _orderItems.clear();
      _addNewItem(); // Add first item
      
      final now = DateTime.now();
      _dateController.text = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.mainColor,
      body: SafeArea(
        child: Column(
          children: [
            const HeaderWidget(
              title: "Barang Keluar",
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
                                'Buat Transaksi Barang Keluar',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Status Dropdown
                              const Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<int>(
                                value: _selectedDone,
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
                                  DropdownMenuItem<int>(
                                    value: 0,
                                    child: Text('Pending'),
                                  ),
                                  DropdownMenuItem<int>(
                                    value: 1,
                                    child: Text('Done'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDone = value ?? 0;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              
                              // Date Field
                              const Text(
                                'Tanggal',
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
                              
                              // Description Field
                              const Text(
                                'Deskripsi',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _descController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  hintText: 'Masukkan deskripsi transaksi',
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Masukkan deskripsi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              
                              // Items Section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Daftar Barang',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _addNewItem,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Tambah Barang'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              
                              // Order Items List
                              ..._orderItems.asMap().entries.map((entry) {
                                int index = entry.key;
                                OrderItem item = entry.value;
                                
                                return _buildOrderItemCard(index, item);
                              }).toList(),
                              
                              const SizedBox(height: 32),
                              
                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: _resetForm,
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: AppColors.mainColor),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: Text(
                                        'Reset',
                                        style: TextStyle(
                                          color: AppColors.mainColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _createBatchOrder,
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
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text(
                                              'Buat Transaksi (${_orderItems.length} item)',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
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

  Widget _buildOrderItemCard(int index, OrderItem item) {
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
                if (_orderItems.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeItem(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Brand Dropdown
            const Text(
              'Pabrik/Brand',
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
                  item.barangId = null;
                  item.gudangId = null; // Reset gudang when brand changes
                  item.availableStock = 0;
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
                  item.gudangId = null; // Reset gudang when barang changes
                  item.lantaiId = null;
                  item.availableFloors = [];
                  item.availableStock = 0;
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Gudang Dropdown
            const Text(
              'Gudang Sumber',
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
                  item.lantaiId = null;
                  item.availableStock = 0;
                });
                _updateFloorsForGudang(index);
              },
            ),
            const SizedBox(height: 12),
            
            // Gudang Lantai Dropdown
            const Text(
              'Gudang Lantai',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            AbsorbPointer(
              absorbing: item.gudangId == null || item.availableFloors.isEmpty,
              child: Opacity(
                opacity: item.gudangId == null || item.availableFloors.isEmpty ? 0.5 : 1.0,
                child: SearchableDropdown(
                  value: item.lantaiId,
                  hint: item.gudangId == null 
                      ? 'Pilih Gudang terlebih dahulu' 
                      : (item.availableFloors.isEmpty ? 'Tidak ada lantai tersedia' : 'Pilih Lantai'),
                  items: item.availableFloors.map((floor) {
                    return DropdownMenuItem<String>(
                      value: floor['lantai_id'],
                      child: Text('${floor['gudang_nama']} - ${floor['lantai_nama']} (Stok: ${floor['stock_barang']})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      item.lantaiId = value;
                    });
                    _updateStockForItem(index);
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Amount Field with Stock Display
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
                      TextFormField(
                        initialValue: item.amount > 0 ? item.amount.toString() : '',
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
                            item.amount = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (item.lantaiId != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.availableStock > 0 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.red.withOpacity(0.1),
                      border: Border.all(
                        color: item.availableStock > 0 ? Colors.green : Colors.red,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Stok Lantai',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${item.availableStock}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: item.availableStock > 0 ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
