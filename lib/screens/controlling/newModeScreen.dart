import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class NewModeScreen extends StatefulWidget {
  const NewModeScreen({super.key});

  @override
  State<NewModeScreen> createState() => _NewModeScreenState();
}

class _NewModeScreenState extends State<NewModeScreen> {
  bool saveMode = false;
  String selectedMode = "Power";
  String selectedPower = "11";
  String selectedDuration = "4 h";
  final TextEditingController _modeNameController = TextEditingController();
  final FixedExtentScrollController _modeScrollController = FixedExtentScrollController();
  final FixedExtentScrollController _powerScrollController = FixedExtentScrollController();
  final FixedExtentScrollController _durationScrollController = FixedExtentScrollController();
  List<Map<String, String>> additionalSteps = [];
  final List<FixedExtentScrollController> _additionalPowerControllers = [];
  final List<FixedExtentScrollController> _additionalDurationControllers = [];

  @override
  void initState() {
    super.initState();
    _additionalPowerControllers.add(FixedExtentScrollController());
    _additionalDurationControllers.add(FixedExtentScrollController());
  }

  @override
  void dispose() {
    _modeNameController.dispose();
    _modeScrollController.dispose();
    _powerScrollController.dispose();
    _durationScrollController.dispose();
    for (var controller in _additionalPowerControllers) {
      controller.dispose();
    }
    for (var controller in _additionalDurationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addStep() {
    setState(() {
      additionalSteps.add({'power': '1', 'duration': '0 h'});
      _additionalPowerControllers.add(FixedExtentScrollController());
      _additionalDurationControllers.add(FixedExtentScrollController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      additionalSteps.removeAt(index);
      _additionalPowerControllers.removeAt(index + 1);
      _additionalDurationControllers.removeAt(index + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Create New Mode'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: screenSize.width * 0.05,
          vertical: screenSize.height * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  "New Mode",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepOrange,
                  ),
                ),
                const Spacer(),
                Checkbox(
                  value: saveMode,
                  onChanged: (value) => setState(() => saveMode = value!),
                  activeColor: Colors.deepOrange,
                ),
                Text(
                  "Save",
                  style: TextStyle(
                    fontSize: screenSize.width * 0.045,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildModeNameField(isSmallScreen),
            const SizedBox(height: 30),
            _buildConfigurationSection(),
            ..._buildAdditionalSteps(screenSize),
            if (additionalSteps.length < 2) _buildAddStepButton(),
            const SizedBox(height: 40),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildModeNameField(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Mode name",
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _modeNameController,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: isSmallScreen ? 14 : 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.deepOrange, width: 1.5),
            ),
            hintText: 'Enter mode name',
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildConfigurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Configuration"),
        const SizedBox(height: 15),
        _buildOptionCard(
          icon: Icons.settings,
          title: "Select mode",
          value: selectedMode,
          onTap: () => _showModeSelectionDialog(context),
        ),
        const SizedBox(height: 15),
        _buildOptionCard(
          icon: Icons.power_settings_new,
          title: "Select power",
          value: selectedPower,
          onTap: () => _showPowerModeSelectionDialog(context, 0),
        ),
        const SizedBox(height: 15),
        _buildOptionCard(
          icon: Icons.timer,
          title: "Select duration",
          value: selectedDuration,
          onTap: () => _showDurationSelectionDialog(context, 0),
        ),
      ],
    );
  }

  List<Widget> _buildAdditionalSteps(Size screenSize) {
    return additionalSteps.asMap().entries.map((entry) {
      final index = entry.key;
      final step = entry.value;
      return Column(
        children: [
          const SizedBox(height: 30),
          _buildSectionTitle("Step ${index + 2}"),
          const SizedBox(height: 15),
          _buildOptionCard(
            icon: Icons.power_settings_new,
            title: "Select power",
            value: step['power']!,
            onTap: () => _showPowerModeSelectionDialog(context, index + 1),
          ),
          const SizedBox(height: 15),
          _buildOptionCard(
            icon: Icons.timer,
            title: "Select duration",
            value: step['duration']!,
            onTap: () => _showDurationSelectionDialog(context, index + 1),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeStep(index),
            ),
          ),
        ],
      );
    }).toList();
  }

  Widget _buildAddStepButton() {
    return Align(
      alignment: Alignment.center,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepOrange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        onPressed: _addStep,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          "Add Step",
          style: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return BlocConsumer<AppCubit, AppStates>(
      listener: (context, state) {
        if (state is DeviceCommandSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mode sent successfully!')),
          );
          Navigator.pop(context);
        } else if (state is DeviceCommandError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        return ElevatedButton(
          onPressed: () {
            if (_modeNameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a mode name')),
              );
              return;
            }
            BlocProvider.of<AppCubit>(context).sendMultiStepCommand(
              modeName: _modeNameController.text,
              modeType: selectedMode,
              steps: [
                {'power': selectedPower, 'duration': selectedDuration},
                ...additionalSteps,
              ],
              saveMode: saveMode,
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: state is DeviceCommandSending
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text(
                  "Send",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey.shade700,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Colors.deepOrange),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  // Dialog methods remain the same but with 'Cooker' replaced with 'Device'
  void _showModeSelectionDialog(BuildContext context) {
    final options = ["Power", "Temperature"];
    _showWheelSelectionDialog(
      context: context,
      title: "Select Mode",
      options: options,
      initialIndex: options.indexOf(selectedMode),
      controller: _modeScrollController,
      onSelected: (value) => setState(() => selectedMode = value),
    );
  }

  void _showPowerModeSelectionDialog(BuildContext context, int stepIndex) {
    final options = List<String>.generate(99, (index) => (index + 1).toString());
    String currentValue;
    Function(String) onSelected;

    if (stepIndex == 0) {
      currentValue = selectedPower;
      onSelected = (value) => setState(() => selectedPower = value);
    } else {
      currentValue = additionalSteps[stepIndex - 1]['power']!;
      onSelected = (value) => setState(() {
        additionalSteps[stepIndex - 1]['power'] = value;
      });
    }

    final currentInt = int.tryParse(currentValue) ?? 1;
    final initialIndex = currentInt.clamp(1, 99) - 1;
    
    _showWheelSelectionDialog(
      context: context,
      title: "Select Power Level (1-99)",
      options: options,
      initialIndex: initialIndex,
      controller: stepIndex == 0 
          ? _powerScrollController 
          : _additionalPowerControllers[stepIndex],
      onSelected: onSelected,
    );
  }

  void _showDurationSelectionDialog(BuildContext context, int stepIndex) {
    // ... (same implementation as original)
  }

  void _showWheelSelectionDialog({
    required BuildContext context,
    required String title,
    required List<String> options,
    required int initialIndex,
    required FixedExtentScrollController controller,
    required Function(String) onSelected,
  }) {
    // ... (same implementation as original)
  }
}