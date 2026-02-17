import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/analytics_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

enum GstType { cgstSgst, igst, noGst }

enum CalculatorMode { normal, gstBilling }

class AdvancedCalculatorScreen extends StatefulWidget {
  const AdvancedCalculatorScreen({super.key, this.withScaffold = false});

  final bool withScaffold;

  @override
  State<AdvancedCalculatorScreen> createState() =>
      _AdvancedCalculatorScreenState();
}

class _AdvancedCalculatorScreenState extends State<AdvancedCalculatorScreen> {
  static const List<_CalculatorKey> _calculatorKeys = <_CalculatorKey>[
    _CalculatorKey('MC', _CalculatorKeyType.memory),
    _CalculatorKey('MR', _CalculatorKeyType.memory),
    _CalculatorKey('M+', _CalculatorKeyType.memory),
    _CalculatorKey('M-', _CalculatorKeyType.memory),
    _CalculatorKey('C', _CalculatorKeyType.utility),
    _CalculatorKey('(', _CalculatorKeyType.special),
    _CalculatorKey(')', _CalculatorKeyType.special),
    _CalculatorKey('⌫', _CalculatorKeyType.utility),
    _CalculatorKey('%', _CalculatorKeyType.operatorKey),
    _CalculatorKey('÷', _CalculatorKeyType.operatorKey),
    _CalculatorKey('7', _CalculatorKeyType.number),
    _CalculatorKey('8', _CalculatorKeyType.number),
    _CalculatorKey('9', _CalculatorKeyType.number),
    _CalculatorKey('×', _CalculatorKeyType.operatorKey),
    _CalculatorKey('√', _CalculatorKeyType.special),
    _CalculatorKey('4', _CalculatorKeyType.number),
    _CalculatorKey('5', _CalculatorKeyType.number),
    _CalculatorKey('6', _CalculatorKeyType.number),
    _CalculatorKey('−', _CalculatorKeyType.operatorKey),
    _CalculatorKey('x²', _CalculatorKeyType.special),
    _CalculatorKey('1', _CalculatorKeyType.number),
    _CalculatorKey('2', _CalculatorKeyType.number),
    _CalculatorKey('3', _CalculatorKeyType.number),
    _CalculatorKey('+', _CalculatorKeyType.operatorKey),
    _CalculatorKey('Mkup%', _CalculatorKeyType.special),
    _CalculatorKey('0', _CalculatorKeyType.number),
    _CalculatorKey('.', _CalculatorKeyType.number),
    _CalculatorKey('Disc%', _CalculatorKeyType.special),
    _CalculatorKey('=', _CalculatorKeyType.equals),
    _CalculatorKey('', _CalculatorKeyType.empty),
  ];

  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _markupController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();

  List<String> _tokens = <String>['0'];
  String _result = '0';
  bool _justEvaluated = false;

  double _selectedGstRate = 12;
  GstType _selectedGstType = GstType.cgstSgst;

  double _subtotal = 0;
  double _discountAmount = 0;
  double _markupAmount = 0;
  double _gstAmount = 0;
  double _cgstAmount = 0;
  double _sgstAmount = 0;
  double _igstAmount = 0;
  double _finalTotal = 0;
  double _profitPercent = 0;
  double _marginPercent = 0;
  double _profitAmount = 0;

  CalculatorMode _calculatorMode = CalculatorMode.normal;

  @override
  void initState() {
    super.initState();
    _priceController.addListener(_recalculateBilling);
    _quantityController.addListener(_recalculateBilling);
    _discountController.addListener(_recalculateBilling);
    _markupController.addListener(_recalculateBilling);
    _costPriceController.addListener(_recalculateProfit);
    _sellingPriceController.addListener(_recalculateProfit);
    _recalculateBilling();
    _recalculateProfit();
  }

  @override
  void dispose() {
    _priceController.dispose();
    _quantityController.dispose();
    _discountController.dispose();
    _markupController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    super.dispose();
  }

  bool _isNumberToken(String token) => double.tryParse(token) != null;

  bool _isOperatorToken(String token) =>
      const <String>{'+', '-', '*', '/', '%', 'MU', 'DISC'}.contains(token);

  String get _displayExpression {
    if (_tokens.isEmpty) {
      return '0';
    }
    return _tokens.map(_displayToken).join(' ');
  }

  String _displayToken(String token) {
    switch (token) {
      case '*':
        return '×';
      case '/':
        return '÷';
      case '-':
        return '−';
      case 'MU':
        return 'Mkup%';
      case 'DISC':
        return 'Disc%';
      default:
        return token;
    }
  }

  void _onCalculatorKeyTap(String label) {
    if (label.isEmpty) {
      return;
    }

    if (_isDigit(label)) {
      _appendDigit(label);
      return;
    }

    switch (label) {
      case '.':
        _appendDecimal();
        break;
      case '+':
      case '−':
      case '×':
      case '÷':
      case '%':
      case 'Mkup%':
      case 'Disc%':
        _appendOperator(_toInternalOperator(label));
        break;
      case '(':
        _appendLeftParenthesis();
        break;
      case ')':
        _appendRightParenthesis();
        break;
      case 'C':
        _clearCalculator();
        break;
      case '⌫':
        _backspace();
        break;
      case '=':
        _evaluateExpression();
        break;
      case 'x²':
        _applySquare();
        break;
      case '√':
        _applySquareRoot();
        break;
      case 'MC':
      case 'MR':
      case 'M+':
      case 'M-':
        _showMemoryHint(label);
        break;
      default:
        break;
    }
  }

  bool _isDigit(String value) => RegExp(r'^\d$').hasMatch(value);

  String _toInternalOperator(String value) {
    switch (value) {
      case '−':
        return '-';
      case '×':
        return '*';
      case '÷':
        return '/';
      case 'Mkup%':
        return 'MU';
      case 'Disc%':
        return 'DISC';
      default:
        return value;
    }
  }

  void _appendDigit(String digit) {
    setState(() {
      if (_justEvaluated) {
        _tokens = <String>[digit];
        _result = '0';
        _justEvaluated = false;
        return;
      }

      if (_tokens.length == 1 && _tokens.first == '0') {
        _tokens[0] = digit;
        return;
      }

      if (_tokens.isNotEmpty && _isNumberToken(_tokens.last)) {
        final String current = _tokens.last;
        if (current == '0') {
          _tokens[_tokens.length - 1] = digit;
        } else {
          _tokens[_tokens.length - 1] = '$current$digit';
        }
        return;
      }

      if (_tokens.isNotEmpty && _tokens.last == ')') {
        _tokens.add('*');
      }
      _tokens.add(digit);
    });
  }

  void _appendDecimal() {
    setState(() {
      if (_justEvaluated) {
        _tokens = <String>['0.'];
        _result = '0';
        _justEvaluated = false;
        return;
      }

      if (_tokens.isEmpty) {
        _tokens = <String>['0.'];
        return;
      }

      final String lastToken = _tokens.last;
      if (_isNumberToken(lastToken)) {
        if (!lastToken.contains('.')) {
          _tokens[_tokens.length - 1] = '$lastToken.';
        }
        return;
      }

      if (lastToken == ')') {
        _tokens.add('*');
      }
      _tokens.add('0.');
    });
  }

  void _appendOperator(String operatorToken) {
    setState(() {
      if (_justEvaluated) {
        _tokens = <String>[_result];
        _justEvaluated = false;
      }

      if (_tokens.isEmpty) {
        if (operatorToken == '-') {
          _tokens.add('-');
        }
        return;
      }

      final String lastToken = _tokens.last;

      if (_isOperatorToken(lastToken)) {
        if (operatorToken == '-' && lastToken != '-') {
          _tokens.add(operatorToken);
        } else {
          _tokens[_tokens.length - 1] = operatorToken;
        }
        return;
      }

      if (lastToken == '(') {
        if (operatorToken == '-') {
          _tokens.add(operatorToken);
        }
        return;
      }

      _tokens.add(operatorToken);
    });
  }

  void _appendLeftParenthesis() {
    setState(() {
      if (_justEvaluated) {
        _tokens = <String>['('];
        _result = '0';
        _justEvaluated = false;
        return;
      }

      if (_tokens.length == 1 && _tokens.first == '0') {
        _tokens[0] = '(';
        return;
      }

      if (_tokens.isNotEmpty &&
          (_isNumberToken(_tokens.last) || _tokens.last == ')')) {
        _tokens.add('*');
      }
      _tokens.add('(');
    });
  }

  void _appendRightParenthesis() {
    final int openBrackets = _tokens
        .where((String token) => token == '(')
        .length;
    final int closeBrackets = _tokens
        .where((String token) => token == ')')
        .length;
    if (openBrackets <= closeBrackets || _tokens.isEmpty) {
      return;
    }

    final String lastToken = _tokens.last;
    if (!_isNumberToken(lastToken) && lastToken != ')') {
      return;
    }

    setState(() {
      _tokens.add(')');
      _justEvaluated = false;
    });
  }

  void _clearCalculator() {
    setState(() {
      _tokens = <String>['0'];
      _result = '0';
      _justEvaluated = false;
    });
  }

  void _backspace() {
    setState(() {
      _justEvaluated = false;
      if (_tokens.isEmpty) {
        _tokens = <String>['0'];
        return;
      }

      final String lastToken = _tokens.last;
      if (_isNumberToken(lastToken) && lastToken.length > 1) {
        _tokens[_tokens.length - 1] = lastToken.substring(
          0,
          lastToken.length - 1,
        );
      } else {
        _tokens.removeLast();
      }

      if (_tokens.isEmpty) {
        _tokens = <String>['0'];
      }
    });
  }

  void _evaluateExpression() {
    try {
      final double value = _evaluateTokens(_tokens);
      final String formattedValue = _formatForDisplay(value);
      setState(() {
        _result = formattedValue;
        _tokens = <String>[formattedValue];
        _justEvaluated = true;
      });
    } on FormatException catch (error) {
      _showCalculatorError(error.message);
    } catch (_) {
      _showCalculatorError('Invalid expression');
    }
  }

  void _applySquare() {
    try {
      final double value = _evaluateTokens(_tokens);
      final String formattedValue = _formatForDisplay(value * value);
      setState(() {
        _result = formattedValue;
        _tokens = <String>[formattedValue];
        _justEvaluated = true;
      });
    } on FormatException catch (error) {
      _showCalculatorError(error.message);
    } catch (_) {
      _showCalculatorError('Unable to square current value');
    }
  }

  void _applySquareRoot() {
    try {
      final double value = _evaluateTokens(_tokens);
      if (value < 0) {
        throw const FormatException('Square root needs a non-negative value');
      }
      final String formattedValue = _formatForDisplay(math.sqrt(value));
      setState(() {
        _result = formattedValue;
        _tokens = <String>[formattedValue];
        _justEvaluated = true;
      });
    } on FormatException catch (error) {
      _showCalculatorError(error.message);
    } catch (_) {
      _showCalculatorError('Unable to find square root');
    }
  }

  double _evaluateTokens(List<String> sourceTokens) {
    if (sourceTokens.isEmpty) {
      return 0;
    }
    final _TokenParser parser = _TokenParser(sourceTokens);
    final double value = parser.parse();
    if (value.isInfinite || value.isNaN) {
      throw const FormatException('Result is not a finite number');
    }
    return value;
  }

  String _formatForDisplay(double value) {
    final String fixed = value.toStringAsFixed(6);
    final String compact = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
    return compact.isEmpty ? '0' : compact;
  }

  void _showCalculatorError(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  void _showMemoryHint(String action) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action is UI-only for now.'),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  double _readController(TextEditingController controller) {
    final String value = controller.text.trim();
    if (value.isEmpty) {
      return 0;
    }
    return double.tryParse(value) ?? 0;
  }

  void _recalculateBilling() {
    final double pricePerPiece = _readController(_priceController);
    final double quantity = _readController(_quantityController);
    final double discountPercent = _readController(
      _discountController,
    ).clamp(0, 100);
    final double markupPercent = _readController(
      _markupController,
    ).clamp(0, 1000);

    final double subtotal = pricePerPiece * quantity;
    final double discountAmount = subtotal * (discountPercent / 100);
    final double afterDiscount = subtotal - discountAmount;
    final double markupAmount = afterDiscount * (markupPercent / 100);
    final double taxableAmount = afterDiscount + markupAmount;
    final double gstBaseAmount = subtotal;
    final double gstAmount = _selectedGstType == GstType.noGst
        ? 0
        : gstBaseAmount * (_selectedGstRate / 100);

    double cgstAmount = 0;
    double sgstAmount = 0;
    double igstAmount = 0;
    if (_selectedGstType == GstType.cgstSgst) {
      cgstAmount = gstAmount / 2;
      sgstAmount = gstAmount / 2;
    } else if (_selectedGstType == GstType.igst) {
      igstAmount = gstAmount;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _subtotal = subtotal;
      _discountAmount = discountAmount;
      _markupAmount = markupAmount;
      _gstAmount = gstAmount;
      _cgstAmount = cgstAmount;
      _sgstAmount = sgstAmount;
      _igstAmount = igstAmount;
      _finalTotal = taxableAmount + gstAmount;
    });
  }

  void _recalculateProfit() {
    final double costPrice = _readController(_costPriceController);
    final double sellingPrice = _readController(_sellingPriceController);
    final double profitAmount = sellingPrice - costPrice;
    final double profitPercent = costPrice == 0
        ? 0
        : (profitAmount / costPrice) * 100;
    final double marginPercent = sellingPrice == 0
        ? 0
        : (profitAmount / sellingPrice) * 100;

    if (!mounted) {
      return;
    }
    setState(() {
      _profitAmount = profitAmount;
      _profitPercent = profitPercent;
      _marginPercent = marginPercent;
    });
  }

  String _money(double value) {
    final String sign = value < 0 ? '- ' : '';
    return '$sign₹${value.abs().toStringAsFixed(2)}';
  }

  Future<void> _saveAsInvoiceItem() async {
    try {
      final FirestoreService firestoreService = context
          .read<FirestoreService>();
      final AnalyticsService analyticsService = context
          .read<AnalyticsService>();
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

      final double pricePerPiece = _readController(_priceController);
      final double quantity = _readController(_quantityController);
      final double discountPercent = _readController(
        _discountController,
      ).clamp(0, 100);
      final double markupPercent = _readController(
        _markupController,
      ).clamp(0, 1000);

      if (pricePerPiece <= 0 || quantity <= 0) {
        _showCalculatorError('Enter valid price and quantity before saving.');
        return;
      }

      await firestoreService.addInvoiceFromCalculator(
        pricePerPiece: pricePerPiece,
        quantity: quantity,
        gstRate: _selectedGstRate,
        gstType: _selectedGstType.name,
        discountPercent: discountPercent,
        markupPercent: markupPercent,
      );
      await analyticsService.logEvent('calculator_save_invoice');

      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Saved as invoice draft in Firestore.')),
      );
    } catch (error) {
      _showCalculatorError('Could not save invoice draft: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildModeSwitch(),
          const SizedBox(height: 16),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            child: _calculatorMode == CalculatorMode.normal
                ? _buildCalculatorCard()
                : _buildSmartBillingPanel(),
          ),
          const SizedBox(height: 16),
          _buildLiveResultPreview(),
          const SizedBox(height: 16),
          _buildProfitMarginPanel(),
        ],
      ),
    );

    if (!widget.withScaffold) {
      return content;
    }

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        title: const Text(
          'Advanced GST Calculator',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: content,
    );
  }

  Widget _buildCalculatorCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Advanced Calculator',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: <Color>[Color(0xFF1E2A45), Color(0xFF132036)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    _displayExpression,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder:
                        (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                    child: Text(
                      _result,
                      key: ValueKey<String>(_result),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _calculatorKeys.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (BuildContext context, int index) {
                final _CalculatorKey key = _calculatorKeys[index];
                if (key.type == _CalculatorKeyType.empty) {
                  return const SizedBox.shrink();
                }
                final _KeyStyle style = _styleForKey(key.type);
                return _KeyButton(
                  label: key.label,
                  backgroundColor: style.background,
                  foregroundColor: style.foreground,
                  onTap: () => _onCalculatorKeyTap(key.label),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            Expanded(
              child: ChoiceChip(
                label: const Text('Normal Calculator'),
                selected: _calculatorMode == CalculatorMode.normal,
                onSelected: (_) {
                  setState(() {
                    _calculatorMode = CalculatorMode.normal;
                  });
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('GST Billing Mode'),
                selected: _calculatorMode == CalculatorMode.gstBilling,
                onSelected: (_) {
                  setState(() {
                    _calculatorMode = CalculatorMode.gstBilling;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveResultPreview() {
    final bool gstMode = _calculatorMode == CalculatorMode.gstBilling;
    final String title = gstMode
        ? 'Live Billing Preview'
        : 'Live Calculator Result';
    final String value = gstMode ? _money(_finalTotal) : _result;
    final String subtitle = gstMode
        ? 'GST ${_selectedGstRate.toStringAsFixed(0)}%  •  ${_selectedGstType.name}'
        : 'Expression: $_displayExpression';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2F6FED), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitMarginPanel() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Profit Margin Calculator',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildInputField(
                    controller: _costPriceController,
                    label: 'Cost Price',
                    hintText: '0',
                    icon: Icons.shopping_bag_outlined,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInputField(
                    controller: _sellingPriceController,
                    label: 'Selling Price',
                    hintText: '0',
                    icon: Icons.sell_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildAmountRow(
              'Profit Amount',
              _profitAmount,
              valueColor: _profitAmount >= 0 ? Colors.green : Colors.red,
            ),
            _buildAmountRow(
              'Profit %',
              _profitPercent,
              valueColor: Colors.green.shade700,
              suffix: '%',
            ),
            _buildAmountRow(
              'Margin %',
              _marginPercent,
              valueColor: Colors.blue.shade700,
              suffix: '%',
            ),
          ],
        ),
      ),
    );
  }

  _KeyStyle _styleForKey(_CalculatorKeyType type) {
    switch (type) {
      case _CalculatorKeyType.number:
        return const _KeyStyle(whiteCard, darkText);
      case _CalculatorKeyType.operatorKey:
        return _KeyStyle(primaryBlue.withValues(alpha: 0.12), primaryBlue);
      case _CalculatorKeyType.utility:
        return _KeyStyle(
          Colors.red.withValues(alpha: 0.10),
          Colors.red.shade700,
        );
      case _CalculatorKeyType.memory:
        return _KeyStyle(
          Colors.grey.withValues(alpha: 0.15),
          Colors.blueGrey.shade700,
        );
      case _CalculatorKeyType.special:
        return _KeyStyle(
          Colors.orange.withValues(alpha: 0.14),
          Colors.orange.shade800,
        );
      case _CalculatorKeyType.equals:
        return const _KeyStyle(primaryBlue, Colors.white);
      case _CalculatorKeyType.empty:
        return const _KeyStyle(Colors.transparent, Colors.transparent);
    }
  }

  Widget _buildSmartBillingPanel() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Smart GST Billing Panel',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Client-ready billing simulation with GST split and payable total.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildInputField(
                    controller: _priceController,
                    label: 'Product Price (per piece)',
                    hintText: '0.00',
                    icon: Icons.sell_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInputField(
                    controller: _quantityController,
                    label: 'Quantity',
                    hintText: '1',
                    icon: Icons.inventory_2_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildInputField(
                    controller: _discountController,
                    label: 'Discount % (optional)',
                    hintText: '0',
                    icon: Icons.local_offer_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildInputField(
                    controller: _markupController,
                    label: 'Markup % (optional)',
                    hintText: '0',
                    icon: Icons.trending_up_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'GST Percentage',
              style: TextStyle(fontWeight: FontWeight.w600, color: darkText),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _buildRateChip(0),
                _buildRateChip(5),
                _buildRateChip(12),
                _buildRateChip(18),
                _buildRateChip(28),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              'GST Type',
              style: TextStyle(fontWeight: FontWeight.w600, color: darkText),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildTypeBadge(
                    label: 'CGST + SGST',
                    type: GstType.cgstSgst,
                    color: Colors.orange.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeBadge(
                    label: 'IGST',
                    type: GstType.igst,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTypeBadge(
                    label: 'No GST',
                    type: GstType.noGst,
                    color: Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _recalculateBilling,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text(
                      'Calculate Bill',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saveAsInvoiceItem,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.cloud_upload_outlined),
                    label: const Text(
                      'Save Invoice',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: greyDivider),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Auto Calculation Output',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: darkText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAmountRow('Subtotal', _subtotal),
                  _buildAmountRow(
                    'Discount amount',
                    -_discountAmount,
                    valueColor: Colors.red.shade700,
                  ),
                  _buildAmountRow(
                    'Markup amount',
                    _markupAmount,
                    valueColor: Colors.green.shade700,
                  ),
                  _buildAmountRow(
                    'GST amount',
                    _gstAmount,
                    valueColor: Colors.orange.shade700,
                  ),
                  if (_selectedGstType == GstType.cgstSgst) ...<Widget>[
                    _buildAmountRow(
                      'CGST amount',
                      _cgstAmount,
                      valueColor: Colors.orange.shade800,
                    ),
                    _buildAmountRow(
                      'SGST amount',
                      _sgstAmount,
                      valueColor: Colors.orange.shade800,
                    ),
                  ],
                  if (_selectedGstType == GstType.igst)
                    _buildAmountRow(
                      'IGST amount',
                      _igstAmount,
                      valueColor: Colors.green.shade700,
                    ),
                  const Divider(height: 22, thickness: 1),
                  _buildAmountRow(
                    'Final Total Payable Amount',
                    _finalTotal,
                    emphasize: true,
                    valueColor: primaryBlue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon),
      ),
    );
  }

  Widget _buildRateChip(double rate) {
    final bool selected = _selectedGstRate == rate;
    return ChoiceChip(
      selected: selected,
      label: Text(
        '${rate.toInt()}%',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: selected ? primaryBlue : darkText,
        ),
      ),
      selectedColor: primaryBlue.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: selected ? primaryBlue : greyDivider),
      ),
      onSelected: (_) {
        _selectedGstRate = rate;
        _recalculateBilling();
      },
    );
  }

  Widget _buildTypeBadge({
    required String label,
    required GstType type,
    required Color color,
  }) {
    final bool selected = _selectedGstType == type;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        _selectedGstType = type;
        _recalculateBilling();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? color.withValues(alpha: 0.16) : Colors.white,
          border: Border.all(
            color: selected ? color : greyDivider,
            width: selected ? 1.8 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? color : Colors.black87,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmountRow(
    String label,
    double value, {
    Color? valueColor,
    bool emphasize = false,
    String? suffix,
  }) {
    final String displayValue = suffix == null
        ? _money(value)
        : '${value.toStringAsFixed(2)}$suffix';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.black87,
                fontSize: emphasize ? 16 : 14,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            displayValue,
            style: TextStyle(
              color: valueColor ?? darkText,
              fontSize: emphasize ? 20 : 15,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TokenParser {
  _TokenParser(List<String> tokens) : _tokens = List<String>.from(tokens);

  final List<String> _tokens;
  int _index = 0;

  bool get _isAtEnd => _index >= _tokens.length;

  String get _previous => _tokens[_index - 1];

  double parse() {
    final double value = _parseExpression();
    if (!_isAtEnd) {
      throw const FormatException('Unexpected token sequence');
    }
    return value;
  }

  double _parseExpression() {
    double value = _parseTerm();

    while (_matchAny(const <String>['+', '-', 'MU', 'DISC'])) {
      final String operator = _previous;
      final double right = _parseTerm();
      switch (operator) {
        case '+':
          value += right;
          break;
        case '-':
          value -= right;
          break;
        case 'MU':
          value += value * (right / 100);
          break;
        case 'DISC':
          value -= value * (right / 100);
          break;
      }
    }

    return value;
  }

  double _parseTerm() {
    double value = _parseFactor();

    while (_matchAny(const <String>['*', '/', '%'])) {
      final String operator = _previous;
      final double right = _parseFactor();
      switch (operator) {
        case '*':
          value *= right;
          break;
        case '/':
          if (right == 0) {
            throw const FormatException('Cannot divide by zero');
          }
          value /= right;
          break;
        case '%':
          if (right == 0) {
            throw const FormatException('Cannot modulo by zero');
          }
          value %= right;
          break;
      }
    }

    return value;
  }

  double _parseFactor() {
    if (_match('-')) {
      return -_parseFactor();
    }
    if (_match('+')) {
      return _parseFactor();
    }

    if (_match('(')) {
      final double value = _parseExpression();
      _consume(')');
      return value;
    }

    if (_isAtEnd) {
      throw const FormatException('Expression cannot end here');
    }

    final String token = _advance();
    final double? parsed = double.tryParse(token);
    if (parsed == null) {
      throw const FormatException('Invalid number');
    }
    return parsed;
  }

  String _advance() => _tokens[_index++];

  bool _matchAny(List<String> expectedTokens) {
    if (_isAtEnd) {
      return false;
    }
    if (!expectedTokens.contains(_tokens[_index])) {
      return false;
    }
    _index++;
    return true;
  }

  bool _match(String expected) {
    if (_isAtEnd || _tokens[_index] != expected) {
      return false;
    }
    _index++;
    return true;
  }

  void _consume(String expected) {
    if (!_match(expected)) {
      throw const FormatException('Unbalanced brackets');
    }
  }
}

class _CalculatorKey {
  const _CalculatorKey(this.label, this.type);

  final String label;
  final _CalculatorKeyType type;
}

enum _CalculatorKeyType {
  number,
  operatorKey,
  utility,
  memory,
  special,
  equals,
  empty,
}

class _KeyStyle {
  const _KeyStyle(this.background, this.foreground);

  final Color background;
  final Color foreground;
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _pressed ? 0.95 : 1,
      duration: const Duration(milliseconds: 110),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.backgroundColor == whiteCard
                  ? greyDivider
                  : Colors.transparent,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapCancel: () => setState(() => _pressed = false),
            onTapUp: (_) => setState(() => _pressed = false),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.foregroundColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
