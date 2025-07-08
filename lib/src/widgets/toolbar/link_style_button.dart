import 'dart:ui';

import 'package:flutter/material.dart';

import '../../models/documents/attribute.dart';
import '../../models/rules/insert.dart';
import '../../models/structs/link_dialog_action.dart';
import '../../models/themes/quill_dialog_theme.dart';
import '../../models/themes/quill_icon_theme.dart';
import '../../translations/toolbar.i18n.dart';
import '../controller.dart';
import '../link.dart';
import '../toolbar.dart';

// ignore: must_be_immutable
class LinkStyleButton extends StatefulWidget {
  LinkStyleButton({
    required this.controller,
    this.iconSize = kDefaultIconSize,
    this.icon,
    this.iconTheme,
    this.dialogTheme,
    this.afterButtonPressed,
    this.tooltip,
    this.linkRegExp,
    this.linkDialogAction,
    this.applyButtonColor,
    this.applyButtonstyle,
    this.borderColor,
    this.cancelButtonstyle,
    this.cancelTextColor,
    this.backgroundColor,
    Key? key,
  }) : super(key: key);

  final QuillController controller;
  final IconData? icon;
  final double iconSize;
  final QuillIconTheme? iconTheme;
  final QuillDialogTheme? dialogTheme;
  final VoidCallback? afterButtonPressed;
  final String? tooltip;
  final RegExp? linkRegExp;
  final LinkDialogAction? linkDialogAction;
  Color? borderColor;
  Color? applyButtonColor;
  Color? cancelTextColor;
  TextStyle? applyButtonstyle;
  TextStyle? cancelButtonstyle;
  Color? backgroundColor;

  @override
  _LinkStyleButtonState createState() => _LinkStyleButtonState();
}

class _LinkStyleButtonState extends State<LinkStyleButton> {
  void _didChangeSelection() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_didChangeSelection);
  }

  @override
  void didUpdateWidget(covariant LinkStyleButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_didChangeSelection);
      widget.controller.addListener(_didChangeSelection);
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(_didChangeSelection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToggled = _getLinkAttributeValue() != null;
    final pressedHandler = () => _openLinkDialog(context);
    return QuillIconButton(
      tooltip: widget.tooltip,
      highlightElevation: 0,
      hoverElevation: 0,
      size: widget.iconSize * kIconButtonFactor,
      icon: Icon(
        widget.icon ?? Icons.link,
        size: widget.iconSize,
        color: isToggled
            ? (widget.iconTheme?.iconSelectedColor ?? theme.primaryIconTheme.color)
            : (widget.iconTheme?.iconUnselectedColor ?? theme.iconTheme.color),
      ),
      fillColor: isToggled
          ? (widget.iconTheme?.iconSelectedFillColor ?? Theme.of(context).primaryColor)
          : (widget.iconTheme?.iconUnselectedFillColor ?? theme.canvasColor),
      borderRadius: widget.iconTheme?.borderRadius ?? 2,
      onPressed: pressedHandler,
      afterPressed: widget.afterButtonPressed,
    );
  }

  void _openLinkDialog(BuildContext context) {
    showDialog<_TextLink>(
      context: context,
      builder: (ctx) {
        final link = _getLinkAttributeValue();
        final index = widget.controller.selection.start;

        var text;
        if (link != null) {
          // text should be the link's corresponding text, not selection
          final leaf = widget.controller.document.querySegmentLeafNode(index).leaf;
          if (leaf != null) {
            text = leaf.toPlainText();
          }
        }

        final len = widget.controller.selection.end - index;
        text ??= len == 0 ? '' : widget.controller.document.getPlainText(index, len);
        return _LinkDialog(
          dialogTheme: widget.dialogTheme,
          link: link,
          text: text,
          linkRegExp: widget.linkRegExp,
          action: widget.linkDialogAction,
          borderColor: widget.borderColor,
          applyButtonColor: widget.applyButtonColor,
          applyButtonstyle: widget.applyButtonstyle,
          cancelButtonstyle: widget.cancelButtonstyle,
          cancelTextColor: widget.cancelTextColor,
          backgroundColor: widget.backgroundColor,
        );
      },
    ).then(
      (value) {
        if (value != null) _linkSubmitted(value);
      },
    );
  }

  String? _getLinkAttributeValue() {
    return widget.controller.getSelectionStyle().attributes[Attribute.link.key]?.value;
  }

  void _linkSubmitted(_TextLink value) {
    var index = widget.controller.selection.start;
    var length = widget.controller.selection.end - index;
    if (_getLinkAttributeValue() != null) {
      // text should be the link's corresponding text, not selection
      final leaf = widget.controller.document.querySegmentLeafNode(index).leaf;
      if (leaf != null) {
        final range = getLinkRange(leaf);
        index = range.start;
        length = range.end - range.start;
      }
    }
    widget.controller.replaceText(index, length, value.text, null);
    widget.controller.formatText(index, value.text.length, LinkAttribute(value.link));
  }
}

// ignore: must_be_immutable
class _LinkDialog extends StatefulWidget {
  _LinkDialog({
    this.dialogTheme,
    this.link,
    this.text,
    this.linkRegExp,
    this.action,
    this.applyButtonColor,
    this.applyButtonstyle,
    this.borderColor,
    this.cancelButtonstyle,
    this.cancelTextColor,
    this.backgroundColor,
    Key? key,
  }) : super(key: key);

  final QuillDialogTheme? dialogTheme;
  final String? link;
  final String? text;
  final RegExp? linkRegExp;
  final LinkDialogAction? action;
  Color? backgroundColor;
  Color? borderColor;
  Color? applyButtonColor;
  Color? cancelTextColor;
  Color? primaryColor;
  TextStyle? applyButtonstyle;
  TextStyle? cancelButtonstyle;

  @override
  _LinkDialogState createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  late String _link;
  late String _text;
  late RegExp linkRegExp;
  late TextEditingController _linkController;
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _link = widget.link ?? '';
    _text = widget.text ?? '';
    linkRegExp = widget.linkRegExp ?? AutoFormatMultipleLinksRule.linkRegExp;
    _linkController = TextEditingController(text: _link);
    _textController = TextEditingController(text: _text);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Theme(
      data: ThemeData(
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        backgroundColor: widget.backgroundColor ?? Theme.of(context).canvasColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: screenWidth,
            maxWidth: screenWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Text(
                    'Insert Link',
                    style: TextStyle(
                      fontSize: 18,
                      color: widget.applyButtonColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(color: widget.applyButtonColor),
                  decoration: _inputDecoration(label: 'Text'.i18n),
                  autofocus: true,
                  cursorColor: widget.applyButtonColor,
                  onChanged: _textChanged,
                  controller: _textController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  keyboardType: TextInputType.multiline,
                  style: TextStyle(color: widget.applyButtonColor),
                  decoration: _inputDecoration(label: 'Link'.i18n),
                  autofocus: true,
                  onChanged: _linkChanged,
                  cursorColor: widget.applyButtonColor,
                  controller: _linkController,
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel'.i18n,
                        style: widget.cancelButtonstyle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _okButton(),
                    const SizedBox(width: 10),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: widget.applyButtonColor?.withValues(alpha: 0.5),
        fontSize: 16,
        fontWeight: FontWeight.w300,
      ),
      floatingLabelStyle: TextStyle(
        color: widget.applyButtonColor,
        fontSize: 20,
        fontWeight: FontWeight.w500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: widget.applyButtonColor ?? Colors.grey.shade400),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: widget.applyButtonColor ?? Colors.grey.shade400),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: widget.applyButtonColor ?? widget.dialogTheme?.labelTextStyle?.color ?? Colors.blue,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _okButton() {
    if (widget.action != null) {
      return widget.action!.builder(_canPress(), _applyLink);
    }

    return MaterialButton(
      color: widget.applyButtonColor ?? Colors.blue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        // ignore: lines_longer_than_80_chars
        side: _canPress()
            ? BorderSide.none
            : BorderSide(
                color: widget.applyButtonColor!.withValues(alpha: 0.2),
              ),
      ),
      splashColor: Colors.transparent,
      onPressed: _canPress() ? _applyLink : null,
      child: Text(
        'Apply'.i18n,
        // ignore: lines_longer_than_80_chars
        style: _canPress()
            ? widget.applyButtonstyle
            : TextStyle(
                color: widget.borderColor?.withValues(alpha: 0.4),
              ),
      ),
    );
  }

  bool _canPress() {
    if (_text.isEmpty || _link.isEmpty) {
      return false;
    }
    if (!linkRegExp.hasMatch(_link)) {
      return false;
    }

    return true;
  }

  void _linkChanged(String value) {
    setState(() {
      _link = value;
    });
  }

  void _textChanged(String value) {
    setState(() {
      _text = value;
    });
  }

  void _applyLink() {
    Navigator.pop(context, _TextLink(_text.trim(), _link.trim()));
  }
}

class _TextLink {
  _TextLink(
    this.text,
    this.link,
  );

  final String text;
  final String link;
}
