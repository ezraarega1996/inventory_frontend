import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventory_frontend/models/business.dart';
import 'package:inventory_frontend/services/business_service.dart';

class BusinessDetailScreen extends StatefulWidget {
  final Business business;

  const BusinessDetailScreen({
    super.key,
    required this.business,
  });

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  late Business _business;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _business = widget.business;
  }

  Future<void> _updateBusiness() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final businessService = Provider.of<BusinessService>(context, listen: false);
      final updatedBusiness = await businessService.updateBusiness(
        _business.id,
        _business,
      );
      setState(() {
        _business = updatedBusiness;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business updated successfully')),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // TODO: Upload image to server and update business logo
      setState(() {
        _business = _business.copyWith(logo: image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_business.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _updateBusiness,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_business.logo != null)
                          Center(
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(_business.logo!),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _business.name,
                          decoration: const InputDecoration(
                            labelText: 'Business Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a business name';
                            }
                            return null;
                          },
                          onChanged: (value) {
                            setState(() {
                              _business = _business.copyWith(name: value);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _business.address,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _business = _business.copyWith(address: value);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _business.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _business = _business.copyWith(phone: value);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          initialValue: _business.email,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          onChanged: (value) {
                            setState(() {
                              _business = _business.copyWith(email: value);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile(
                          title: const Text('Active'),
                          value: _business.isActive,
                          onChanged: (value) {
                            setState(() {
                              _business = _business.copyWith(isActive: value);
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Subscription Details',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Plan: ${_business.subscriptionPlan}'),
                                Text('Status: ${_business.subscriptionStatus}'),
                                if (_business.trialEndsAt != null)
                                  Text(
                                    'Trial Ends: ${_formatDate(_business.trialEndsAt!)}',
                                  ),
                                if (_business.subscriptionEndsAt != null)
                                  Text(
                                    'Subscription Ends: ${_formatDate(_business.subscriptionEndsAt!)}',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
} 