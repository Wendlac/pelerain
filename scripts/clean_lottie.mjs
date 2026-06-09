// One-off script — strips the LottieLab/LottieFiles watermark from the
// splash mascot and the white background rectangle from the search loading
// pictogram. Safe to re-run: it only removes layers matching well-known
// fingerprints.
//
// Usage:  node scripts/clean_lottie.mjs

import { readFileSync, writeFileSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { fileURLToPath } from 'node:url'

const here = dirname(fileURLToPath(import.meta.url))
const lottieDir = join(here, '..', 'assets', 'lottie')

/**
 * Recursively walks the Lottie composition (layers and pre-composed assets)
 * and removes layers that match the predicate.
 */
function stripLayers(json, predicate) {
  const before = JSON.stringify(json).length
  const visit = (container) => {
    if (Array.isArray(container?.layers)) {
      container.layers = container.layers.filter((l) => !predicate(l))
    }
    if (Array.isArray(container?.assets)) {
      for (const asset of container.assets) {
        visit(asset)
      }
    }
  }
  visit(json)
  const after = JSON.stringify(json).length
  return { removedBytes: before - after }
}

// ── splash_mascot.json: remove anything named like a watermark ────────────
//
// LottieLab tags free-tier downloads with a small group layer in the
// bottom-right corner. Two fingerprints catch it reliably:
//   1. The layer name starts with "lottielab" / "lottiefiles" / "lottie"
//      (rare — the name often gets stripped to something generic)
//   2. The layer index is the magic placeholder `12345679`. We've never
//      seen this id used by genuine content.
{
  const path = join(lottieDir, 'splash_mascot.json')
  const json = JSON.parse(readFileSync(path, 'utf8'))
  const watermarkRe = /^(lottielab|lottiefiles|lottie)/i

  const { removedBytes } = stripLayers(json, (layer) => {
    if (typeof layer.nm === 'string' && watermarkRe.test(layer.nm.trim())) {
      return true
    }
    if (layer.ind === 12345679) return true
    return false
  })

  writeFileSync(path, JSON.stringify(json))
  console.log(`splash_mascot.json: watermark removed (-${removedBytes} bytes)`)
}

// ── search_loading.json: remove the white background rectangle layer ──────
{
  const path = join(lottieDir, 'search_loading.json')
  const json = JSON.parse(readFileSync(path, 'utf8'))

  const isWhiteBgLayer = (layer) => {
    if (layer.ty !== 4 || !Array.isArray(layer.shapes)) return false
    // Layer needs at least one rectangle AND a solid-white fill at full opacity
    const hasRect = layer.shapes.some((s) => s.ty === 'rc')
    const hasWhiteFill = layer.shapes.some(
      (s) =>
        s.ty === 'fl' &&
        Array.isArray(s.c?.k) &&
        s.c.k[0] === 1 &&
        s.c.k[1] === 1 &&
        s.c.k[2] === 1 &&
        (s.o?.k === 100 || s.o?.k === undefined)
    )
    return hasRect && hasWhiteFill
  }

  const { removedBytes } = stripLayers(json, isWhiteBgLayer)

  writeFileSync(path, JSON.stringify(json))
  console.log(`search_loading.json: white background removed (-${removedBytes} bytes)`)
}
