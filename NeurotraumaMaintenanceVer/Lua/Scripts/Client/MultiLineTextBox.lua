-- why barotrauma's GUI libraries don't have this implemented by default? this is stupid

local function updateServerMessageScrollBasedOnCaret(textBox, listBox)
    local caretY = textBox.CaretScreenPos.Y;
    local bottomCaretExtent = textBox.Font.LineHeight * 1.5
    local topCaretExtent = -textBox.Font.LineHeight * 0.5

    if caretY + bottomCaretExtent > listBox.Rect.Bottom then
        listBox.ScrollBar.BarScroll
            = (caretY - textBox.Rect.Top - listBox.Rect.Height + bottomCaretExtent)
              / (textBox.Rect.Height - listBox.Rect.Height)
    elseif (caretY + topCaretExtent < listBox.Rect.Top) then
        listBox.ScrollBar.BarScroll
            = (caretY - textBox.Rect.Top + topCaretExtent)
              / (textBox.Rect.Height - listBox.Rect.Height)
    end
end

local function CreateMultiLineTextBox(rectransform, text, size)
    local multineListBox = GUI.ListBox(GUI.RectTransform(Vector2(1, size or 0.2), rectransform))

    local textBox = GUI.TextBox(GUI.RectTransform(Vector2(1, 1), multineListBox.Content.RectTransform), text, nil, nil, nil, true, "GUITextBoxNoBorder") 

    textBox.add_OnSelected(function ()
        updateServerMessageScrollBasedOnCaret(textBox, multineListBox)
    end)

    textBox.OnTextChangedDelegate = function ()
        local textSize = textBox.Font.MeasureString(textBox.WrappedText);
        textBox.RectTransform.NonScaledSize = Point(textBox.RectTransform.NonScaledSize.X, math.max(multineListBox.Content.Rect.Height, textSize.Y + 10))
        multineListBox.UpdateScrollBarSize()

        return true;
    end

    textBox.OnEnterPressed = function ()
        local str = textBox.Text
        local caretIndex = textBox.CaretIndex

        textBox.Text = str:sub(1, caretIndex) .. "\n" .. str:sub(caretIndex + 1)
        textBox.CaretIndex = caretIndex + 1

        return true
    end

    return textBox
end

return CreateMultiLineTextBox