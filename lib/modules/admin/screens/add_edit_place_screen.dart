import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smarttrip_ai/modules/ai_generation/common/app_snack_bar.dart';
import 'package:smarttrip_ai/modules/trending_places/models/trending_place.dart';
import 'package:smarttrip_ai/modules/trending_places/services/trending_places_service.dart';
import 'package:smarttrip_ai/modules/storage/storage_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smarttrip_ai/theme/app_colors.dart';

class AddEditPlaceScreen extends StatefulWidget {
  const AddEditPlaceScreen({super.key, this.place, this.placesService});

  final TrendingPlace? place;
  final TrendingPlacesServiceBase? placesService;

  @override
  State<AddEditPlaceScreen> createState() => _AddEditPlaceScreenState();
}

class _AddEditPlaceScreenState extends State<AddEditPlaceScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();
  final TextEditingController _bestTimeController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _ratingController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  late final TrendingPlacesServiceBase _placesService;
  bool _isSaving = false;
  bool _isUploading = false;

  bool get _isEditing => widget.place != null;

  @override
  void initState() {
    super.initState();
    _placesService = widget.placesService ?? TrendingPlacesService();
    final TrendingPlace? place = widget.place;
    if (place != null) {
      _nameController.text = place.name;
      _countryController.text = place.country;
      _descriptionController.text = place.description;
      _imageUrlController.text = place.imageUrl;
      _bestTimeController.text = place.bestTime;
      _budgetController.text = place.budget;
      _ratingController.text = place.rating == 0
          ? ''
          : place.rating.toStringAsFixed(1);
      _categoryController.text = place.category;
    }
    _imageUrlController.addListener(_refreshImagePreview);
  }

  @override
  void dispose() {
    _imageUrlController
      ..removeListener(_refreshImagePreview)
      ..dispose();
    _nameController.dispose();
    _countryController.dispose();
    _descriptionController.dispose();
    _bestTimeController.dispose();
    _budgetController.dispose();
    _ratingController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (_isUploading) return;
    final ImagePicker picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
      imageQuality: 88,
    );
    if (picked == null) return;

    setState(() => _isUploading = true);
    try {
      final StorageService storage = StorageService();
      final String downloadUrl = await storage.uploadPlaceImage(
        file: picked,
        placeId: widget.place?.id,
      );
      _imageUrlController.text = downloadUrl;
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Image uploaded.');
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Image upload failed.');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _refreshImagePreview() {
    setState(() {});
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _ratingValidator(String? value) {
    final String? requiredError = _requiredValidator(value);
    if (requiredError != null) {
      return requiredError;
    }

    final double? rating = double.tryParse(value!.trim());
    if (rating == null || rating < 0 || rating > 5) {
      return 'Enter 0 to 5';
    }
    return null;
  }

  Future<void> _savePlace() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final TrendingPlace place = TrendingPlace(
      id: widget.place?.id ?? '',
      name: _nameController.text.trim(),
      country: _countryController.text.trim(),
      description: _descriptionController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      bestTime: _bestTimeController.text.trim(),
      budget: _budgetController.text.trim(),
      rating: double.parse(_ratingController.text.trim()),
      category: _categoryController.text.trim(),
      createdAt: widget.place?.createdAt,
      updatedAt: widget.place?.updatedAt,
    );

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await _placesService.updateTrendingPlace(place);
      } else {
        await _placesService.addTrendingPlace(place);
      }

      if (!mounted) {
        return;
      }
      AppSnackBar.showSuccess(
        context,
        _isEditing ? 'Place updated.' : 'Place added.',
      );
      Navigator.of(context).pop(true);
    } on FirebaseException catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(
        context,
        error.message ?? 'Unable to save place. Please check permissions.',
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      AppSnackBar.showError(context, 'Unable to save place right now.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color pageColor = isDarkMode
        ? AppColors.darkBackground
        : AppColors.lightBackground;
    final Color primaryTextColor = isDarkMode
        ? AppColors.accentGreen
        : AppColors.primaryGreen;
    final Color cardColor = isDarkMode ? AppColors.darkSurface : Colors.white;
    final Color borderColor = isDarkMode
        ? AppColors.darkBorder
        : const Color(0x338DA180);

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Place' : 'Add Place',
          style: TextStyle(
            color: primaryTextColor,
            fontFamily: 'Times New Roman',
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: <Widget>[
              _ImagePreviewCard(
                imageUrl: _imageUrlController.text.trim(),
                primaryTextColor: primaryTextColor,
                backgroundColor: cardColor,
                borderColor: borderColor,
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickAndUploadImage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryTextColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: _isUploading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.upload_file_outlined),
                        label: Text(
                          _isUploading ? 'Uploading...' : 'Upload Image',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AdminFormField(
                label: 'Place Name',
                hintText: 'Paris',
                controller: _nameController,
                validator: _requiredValidator,
                primaryTextColor: primaryTextColor,
                fillColor: cardColor,
                borderColor: borderColor,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _AdminFormField(
                label: 'Country / Location',
                hintText: 'France',
                controller: _countryController,
                validator: _requiredValidator,
                primaryTextColor: primaryTextColor,
                fillColor: cardColor,
                borderColor: borderColor,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _AdminFormField(
                label: 'Description',
                hintText: 'Full destination description',
                controller: _descriptionController,
                validator: _requiredValidator,
                primaryTextColor: primaryTextColor,
                fillColor: cardColor,
                borderColor: borderColor,
                enabled: !_isSaving,
                minLines: 4,
                maxLines: 7,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 16),
              _AdminFormField(
                label: 'Image URL',
                hintText: 'https://example.com/image.jpg',
                controller: _imageUrlController,
                validator: _requiredValidator,
                primaryTextColor: primaryTextColor,
                fillColor: cardColor,
                borderColor: borderColor,
                enabled: !_isSaving,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _AdminFormField(
                label: 'Best Time',
                hintText: 'April - June',
                controller: _bestTimeController,
                validator: _requiredValidator,
                primaryTextColor: primaryTextColor,
                fillColor: cardColor,
                borderColor: borderColor,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _AdminFormField(
                label: 'Budget',
                hintText: 'Medium',
                controller: _budgetController,
                validator: _requiredValidator,
                primaryTextColor: primaryTextColor,
                fillColor: cardColor,
                borderColor: borderColor,
                enabled: !_isSaving,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _AdminFormField(
                label: 'Rating',
                hintText: '4.8',
                controller: _ratingController,
                validator: _ratingValidator,
                primaryTextColor: primaryTextColor,
                fillColor: cardColor,
                borderColor: borderColor,
                enabled: !_isSaving,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              _AdminFormField(
                label: 'Category / Tag',
                hintText: 'Optional',
                controller: _categoryController,
                primaryTextColor: primaryTextColor,
                fillColor: cardColor,
                borderColor: borderColor,
                enabled: !_isSaving,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _savePlace(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _savePlace,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTextColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Icon(_isEditing ? Icons.save_outlined : Icons.add),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _isEditing
                        ? 'Update'
                        : 'Save',
                    style: const TextStyle(
                      fontFamily: 'Times New Roman',
                      fontSize: 19,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImagePreviewCard extends StatelessWidget {
  const _ImagePreviewCard({
    required this.imageUrl,
    required this.primaryTextColor,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String imageUrl;
  final Color primaryTextColor;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: imageUrl.isEmpty
              ? _PreviewPlaceholder(primaryTextColor: primaryTextColor)
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder:
                      (
                        BuildContext context,
                        Widget child,
                        ImageChunkEvent? loadingProgress,
                      ) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(
                          child: CircularProgressIndicator(
                            color: primaryTextColor,
                            strokeWidth: 2,
                          ),
                        );
                      },
                  errorBuilder: (_, __, ___) {
                    return _PreviewPlaceholder(
                      primaryTextColor: primaryTextColor,
                      message: 'Image preview unavailable',
                    );
                  },
                ),
        ),
      ),
    );
  }
}

class _PreviewPlaceholder extends StatelessWidget {
  const _PreviewPlaceholder({
    required this.primaryTextColor,
    this.message = 'Image preview',
  });

  final Color primaryTextColor;
  final String message;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: primaryTextColor.withValues(alpha: 0.08),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.image_outlined, color: primaryTextColor, size: 38),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: primaryTextColor.withValues(alpha: 0.68),
                fontFamily: 'Times New Roman',
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminFormField extends StatelessWidget {
  const _AdminFormField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.primaryTextColor,
    required this.fillColor,
    required this.borderColor,
    required this.enabled,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.minLines = 1,
    this.maxLines = 1,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final Color primaryTextColor;
  final Color fillColor;
  final Color borderColor;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: TextStyle(
            color: primaryTextColor,
            fontFamily: 'Times New Roman',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          minLines: minLines,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          cursorColor: primaryTextColor,
          style: TextStyle(
            color: primaryTextColor,
            fontFamily: 'Times New Roman',
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: primaryTextColor.withValues(alpha: 0.45),
              fontFamily: 'Times New Roman',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryTextColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
