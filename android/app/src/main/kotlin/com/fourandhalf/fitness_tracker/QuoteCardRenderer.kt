package com.fourandhalf.fitness_tracker

import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.graphics.Typeface
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import android.text.TextUtils
import androidx.core.content.res.ResourcesCompat
import androidx.core.graphics.PathParser
import kotlin.math.max
import kotlin.math.roundToInt

/** Pearl Ledger tokens the widget needs, from the app's light and dark palettes. */
private class Palette(
    val card: Int,
    val surface: Int,
    val border: Int,
    val edge: Int,
    val primary: Int,
    val onPrimary: Int,
    val text: Int,
    val secondary: Int,
)

private val LIGHT = Palette(
    card = 0xFFF1F1F3.toInt(), surface = 0xFFECECEE.toInt(), border = 0xFFDADADD.toInt(),
    edge = 0xB3FFFFFF.toInt(), primary = 0xFF2A2A2D.toInt(), onPrimary = 0xFFFFFFFF.toInt(),
    text = 0xFF1C1C1E.toInt(), secondary = 0xFF626267.toInt(),
)
private val DARK = Palette(
    card = 0xFF161618.toInt(), surface = 0xFF1C1C1F.toInt(), border = 0xFF2C2C30.toInt(),
    edge = 0xFF2C2C30.toInt(), primary = 0xFFECECEE.toInt(), onPrimary = 0xFF161618.toInt(),
    text = 0xFFECECEE.toInt(), secondary = 0xFFA0A0A6.toInt(),
)

// Lucide "quote" and "check", drawn on a 24-unit grid.
private const val QUOTE_RIGHT = "M16 3a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2 1 1 0 0 1 1 1v1a2 2 0 0 1-2 2 1 1 0 0 0-1 1v2a1 1 0 0 0 1 1 6 6 0 0 0 6-6V5a2 2 0 0 0-2-2z"
private const val QUOTE_LEFT = "M5 3a2 2 0 0 0-2 2v6a2 2 0 0 0 2 2 1 1 0 0 1 1 1v1a2 2 0 0 1-2 2 1 1 0 0 0-1 1v2a1 1 0 0 0 1 1 6 6 0 0 0 6-6V5a2 2 0 0 0-2-2z"
private const val CHECK = "M20 6 9 17l-5-5"

private const val RADIUS = 20f // AppRadius.lg
private const val DOT = 32f
private const val DOT_GAP_ABOVE = 8f

/**
 * Paints the Home tab's quote card (and, for the 4x2 widget, the week dots) into a bitmap. RemoteViews can't load the bundled
 * JetBrains Mono as text, so the whole widget is drawn here with Home's sizes and colours and shown as one image.
 */
internal object QuoteCardRenderer {
    fun render(
        context: Context,
        widthDp: Float,
        heightDp: Float,
        quote: String,
        source: String,
        /** Seven of done / today / missed / upcoming, or null for the quote card on its own. */
        states: List<String>?,
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val bitmap = Bitmap.createBitmap(
            (widthDp * density).roundToInt().coerceAtLeast(1),
            (heightDp * density).roundToInt().coerceAtLeast(1),
            Bitmap.Config.ARGB_8888,
        )
        val dark = context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES
        val canvas = Canvas(bitmap)
        canvas.scale(density, density)
        val regular = ResourcesCompat.getFont(context, R.font.jetbrains_mono_regular) ?: Typeface.MONOSPACE
        Painter(canvas, widthDp, heightDp, if (dark) DARK else LIGHT, regular).draw(quote, source, states)
        return bitmap
    }

    private class Painter(
        val canvas: Canvas,
        val width: Float,
        val height: Float,
        val colors: Palette,
        val face: Typeface,
    ) {
        fun draw(quote: String, source: String, states: List<String>?) {
            if (states == null) {
                quotePanel(RectF(0f, 0f, width, height), quote, source)
                return
            }
            // The week module's card, with the quote panel inset and the dots beneath.
            val rect = RectF(0.5f, 0.5f, width - 0.5f, height - 0.5f)
            canvas.drawRoundRect(rect, RADIUS, RADIUS, fill(colors.card))
            canvas.drawRoundRect(rect, RADIUS, RADIUS, stroke(colors.edge, 1f))
            val inset = 8f
            val dotsTop = height - inset - 2f - DOT
            quotePanel(RectF(inset, inset, width - inset, dotsTop - DOT_GAP_ABOVE), quote, source)
            dots(states, dotsTop)
        }

        private fun quotePanel(panel: RectF, quote: String, source: String) {
            canvas.drawRoundRect(panel, RADIUS, RADIUS, fill(colors.surface))
            val padH = 16f
            val padV = if (panel.height() < 90f) 10f else 16f
            val iconSize = 20f
            val gap = 12f
            val textLeft = panel.left + padH + iconSize + gap
            val textWidth = panel.right - padH - textLeft
            val availHeight = panel.height() - 2 * padV

            // Home uses 13 / 11 with 19 / 15 line heights and a 6 gap; shrink together until it fits.
            var size = 13f
            var layout: StaticLayout
            var sourceLine: Float
            var gapPx: Float
            while (true) {
                layout = quoteLayout(quote, size, textWidth, Int.MAX_VALUE)
                sourceLine = 15f * size / 13f
                gapPx = 6f * size / 13f
                if (layout.height + gapPx + sourceLine <= availHeight || size <= 9f) break
                size -= 0.5f
            }
            if (layout.height + gapPx + sourceLine > availHeight) {
                // Still too tall at the smallest size: keep as many lines as fit and end with an ellipsis.
                val lineHeight = layout.height.toFloat() / layout.lineCount
                val lines = max(1, ((availHeight - gapPx - sourceLine) / lineHeight).toInt())
                layout = quoteLayout(quote, size, textWidth, lines)
            }
            val block = layout.height + gapPx + sourceLine
            val top = panel.top + padV + max(0f, (availHeight - block) / 2)

            drawQuoteIcon(panel.left + padH, top + 1f, iconSize)

            canvas.save()
            canvas.translate(textLeft, top)
            layout.draw(canvas)
            canvas.restore()

            val sourcePaint = textPaint(size * 11f / 13f, colors.secondary)
            val metrics = sourcePaint.fontMetrics
            val baseline = top + layout.height + gapPx + (sourceLine - (metrics.descent - metrics.ascent)) / 2 - metrics.ascent
            canvas.drawText(
                TextUtils.ellipsize(source, sourcePaint, textWidth, TextUtils.TruncateAt.END).toString(),
                textLeft,
                baseline,
                sourcePaint,
            )
        }

        private fun quoteLayout(quote: String, size: Float, width: Float, maxLines: Int): StaticLayout {
            val paint = textPaint(size, colors.text)
            val natural = paint.fontMetrics.descent - paint.fontMetrics.ascent
            return StaticLayout.Builder.obtain(quote, 0, quote.length, paint, width.toInt())
                .setLineSpacing(0f, (19f * size / 13f) / natural)
                .setIncludePad(false)
                .setMaxLines(maxLines)
                .setEllipsize(TextUtils.TruncateAt.END)
                .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                .build()
        }

        private fun textPaint(size: Float, color: Int) = TextPaint(Paint.ANTI_ALIAS_FLAG).apply {
            typeface = face
            textSize = size
            this.color = color
        }

        private fun drawQuoteIcon(x: Float, y: Float, size: Float) {
            val paint = stroke(colors.secondary, 2.5f).apply {
                strokeCap = Paint.Cap.ROUND
                strokeJoin = Paint.Join.ROUND
            }
            canvas.save()
            canvas.translate(x, y)
            canvas.scale(size / 24f, size / 24f)
            // The stroke width above is in the 24-unit grid, so it scales with the icon.
            canvas.drawPath(PathParser.createPathFromPathData(QUOTE_RIGHT), paint)
            canvas.drawPath(PathParser.createPathFromPathData(QUOTE_LEFT), paint)
            canvas.restore()
        }

        /** Home's week dots: filled with a check when trained, ringed for today, outlined otherwise. */
        private fun dots(states: List<String>, top: Float) {
            val margin = 4f
            val cell = (width - 2 * (8f + margin)) / 7f
            val cy = top + DOT / 2
            states.take(7).forEachIndexed { index, state ->
                val cx = 8f + margin + cell * index + cell / 2
                val r = DOT / 2
                when (state) {
                    "done" -> {
                        canvas.drawCircle(cx, cy, r - 0.5f, fill(colors.primary))
                        canvas.drawCircle(cx, cy, r - 0.5f, stroke(colors.primary, 1f))
                        val check = stroke(colors.onPrimary, 2f).apply {
                            strokeCap = Paint.Cap.ROUND
                            strokeJoin = Paint.Join.ROUND
                        }
                        canvas.save()
                        canvas.translate(cx - 8f, cy - 8f)
                        canvas.scale(16f / 24f, 16f / 24f)
                        canvas.drawPath(PathParser.createPathFromPathData(CHECK), check)
                        canvas.restore()
                    }
                    "today" -> {
                        canvas.drawCircle(cx, cy, r - 0.75f, fill(colors.surface))
                        canvas.drawCircle(cx, cy, r - 0.75f, stroke(colors.primary, 1.5f))
                    }
                    "missed" -> {
                        canvas.drawCircle(cx, cy, r - 0.5f, fill(colors.surface))
                        canvas.drawCircle(cx, cy, r - 0.5f, stroke(colors.border, 1f))
                    }
                    else -> canvas.drawCircle(cx, cy, r - 0.5f, stroke(colors.border, 1f))
                }
            }
        }

        private fun fill(color: Int) = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }

        private fun stroke(color: Int, width: Float) = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = width
            this.color = color
        }
    }
}
