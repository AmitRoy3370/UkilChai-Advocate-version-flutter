// lib/Farayez/farayez_calculator.dart
// Ukil Farayez Calculator — React engine থেকে পোর্ট করা হয়েছে (Asset-based)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ============================================================================
// ১. FRACTION CLASS (BigInt-ভিত্তিক নির্ভুল ভগ্নাংশ)
// ============================================================================
class Fraction {
  final BigInt num;
  final BigInt den;

  Fraction(BigInt n, [BigInt? d]) : num = n, den = d ?? BigInt.one {
    if (den == BigInt.zero) throw Exception('den=0');
  }

  static Fraction fromInt(int n) => Fraction(BigInt.from(n));
  static Fraction zero() => Fraction(BigInt.zero);
  static Fraction one() => Fraction(BigInt.one);

  static BigInt _gcd(BigInt a, BigInt b) {
    a = a.abs();
    b = b.abs();
    while (b != BigInt.zero) {
      final t = b;
      b = a % b;
      a = t;
    }
    return a == BigInt.zero ? BigInt.one : a;
  }

  Fraction _norm(BigInt n, BigInt d) {
    if (d == BigInt.zero) throw Exception('den=0');
    if (d.isNegative) {
      n = -n;
      d = -d;
    }
    final g = _gcd(n, d);
    return Fraction(n ~/ g, d ~/ g);
  }

  Fraction add(Fraction o) => _norm(num * o.den + o.num * den, den * o.den);
  Fraction sub(Fraction o) => _norm(num * o.den - o.num * den, den * o.den);
  Fraction mul(Fraction o) => _norm(num * o.num, den * o.den);
  Fraction div(Fraction o) => _norm(num * o.den, den * o.num);
  Fraction scaleInt(int n) => mul(Fraction.fromInt(n));

  bool isZero() => num == BigInt.zero;
  bool gt(Fraction o) => num * o.den > o.num * den;
  bool lt(Fraction o) => num * o.den < o.num * den;

  double toNumber() => num.toDouble() / den.toDouble();

  String toPercent([int dp = 2]) {
    final scale = BigInt.from(10).pow(dp);
    final numerator = num * BigInt.from(100) * scale * BigInt.two + den;
    final percentScaled = numerator ~/ (den * BigInt.two);
    final value = percentScaled.toDouble() / scale.toDouble();
    return '${value.toStringAsFixed(dp)}%';
  }

  @override
  String toString() => '$num/$den';
}

Fraction sumFractions(List<Fraction> list) =>
    list.fold(Fraction.zero(), (a, f) => a.add(f));

// ============================================================================
// ২. ASSET META
// ============================================================================
class AssetMeta {
  final String key;
  final String label;
  final String unit;
  final String icon;
  final String hint;
  final int decimals;

  const AssetMeta({
    required this.key,
    required this.label,
    required this.unit,
    required this.icon,
    required this.hint,
    required this.decimals,
  });
}

const List<AssetMeta> assetMetaList = [
  AssetMeta(key: 'land', label: 'জমি', unit: 'শতাংশ', icon: '🌾', hint: 'যেমন: 12.5', decimals: 4),
  AssetMeta(key: 'gold', label: 'স্বর্ণ', unit: 'ভরি', icon: '🪙', hint: 'যেমন: 8.5', decimals: 4),
  AssetMeta(key: 'cash', label: 'টাকা', unit: '৳', icon: '💵', hint: 'যেমন: 500000', decimals: 2),
];

const List<String> assetKeys = ['land', 'gold', 'cash'];

String formatAmount(String key, double n) {
  final meta = assetMetaList.firstWhere((m) => m.key == key);
  if (key == 'cash') {
    // Simple Indian-style formatting without intl package
    final str = n.toStringAsFixed(2);
    final parts = str.split('.');
    var intPart = parts[0];
    final decPart = parts[1];
    // Add commas
    String result = '';
    int count = 0;
    for (int i = intPart.length - 1; i >= 0; i--) {
      result = intPart[i] + result;
      count++;
      if (count == 3 && i != 0) {
        result = ',$result';
        count = 0;
      }
    }
    return '৳ $result.$decPart';
  }
  final trimmed = n.toStringAsFixed(meta.decimals);
  final trimmedNum = double.parse(trimmed).toString();
  return '$trimmedNum ${meta.unit}';
}

double parseAmount(String v) {
  final n = double.tryParse(v);
  return (n != null && n > 0) ? n : 0;
}

// ============================================================================
// ৩. RULES
// ============================================================================
const String PROFILE_ID = 'BD-HANAFI-1.0.0';

class FixedShareRule {
  final String id;
  final String heirCode;
  final Map<String, dynamic> condition;
  final int n;
  final int d;
  final int priority;
  final String src;
  final String exEn;
  final String exBn;

  const FixedShareRule({
    required this.id,
    required this.heirCode,
    required this.condition,
    required this.n,
    required this.d,
    required this.priority,
    required this.src,
    required this.exEn,
    required this.exBn,
  });
}

const List<FixedShareRule> fixedShareRules = [
  FixedShareRule(
    id: 'BD-HANAFI-HUSBAND-001',
    heirCode: 'HUSBAND',
    condition: {'fact': 'descendant.exists', 'equals': false},
    n: 1, d: 2, priority: 10,
    src: 'Quran 4:12',
    exEn: 'Husband receives 1/2 (no qualifying descendant).',
    exBn: 'যোগ্য অধস্তন উত্তরাধিকারী না থাকলে স্বামী ১/২ অংশ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-HUSBAND-002',
    heirCode: 'HUSBAND',
    condition: {'fact': 'descendant.exists', 'equals': true},
    n: 1, d: 4, priority: 10,
    src: 'Quran 4:12',
    exEn: 'Husband receives 1/4 (qualifying descendant exists).',
    exBn: 'যোগ্য অধস্তন উত্তরাধিকারী থাকলে স্বামী ১/৪ অংশ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-WIFE-001',
    heirCode: 'WIFE',
    condition: {'fact': 'descendant.exists', 'equals': false},
    n: 1, d: 4, priority: 10,
    src: 'Quran 4:12',
    exEn: 'Wife/wives collectively receive 1/4 (no qualifying descendant).',
    exBn: 'যোগ্য অধস্তন উত্তরাধিকারী না থাকলে স্ত্রী(গণ) ১/৪ অংশ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-WIFE-002',
    heirCode: 'WIFE',
    condition: {'fact': 'descendant.exists', 'equals': true},
    n: 1, d: 8, priority: 10,
    src: 'Quran 4:12',
    exEn: 'Wife/wives collectively receive 1/8 (qualifying descendant exists).',
    exBn: 'যোগ্য অধস্তন উত্তরাধিকারী থাকলে স্ত্রী(গণ) ১/৮ অংশ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-FATHER-001',
    heirCode: 'FATHER',
    condition: {'fact': 'descendant.exists', 'equals': true},
    n: 1, d: 6, priority: 5,
    src: 'Quran 4:11',
    exEn: 'Father receives fixed 1/6 (descendant exists).',
    exBn: 'যোগ্য অধস্তন উত্তরাধিকারী থাকলে পিতা ১/৬ অংশ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-MOTHER-001',
    heirCode: 'MOTHER',
    condition: {
      'any': [
        {'fact': 'descendant.exists', 'equals': true},
        {'fact': 'sibling.count', 'gte': 2},
      ]
    },
    n: 1, d: 6, priority: 5,
    src: 'Quran 4:11',
    exEn: 'Mother receives 1/6 (descendant or 2+ siblings exist).',
    exBn: 'অধস্তন বা দুই বা ততোধিক ভাই-বোন থাকলে মাতা ১/৬ অংশ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-MOTHER-002',
    heirCode: 'MOTHER',
    condition: {
      'all': [
        {'fact': 'descendant.exists', 'equals': false},
        {'fact': 'sibling.count', 'lt': 2},
      ]
    },
    n: 1, d: 3, priority: 5,
    src: 'Quran 4:11',
    exEn: 'Mother receives 1/3 (no descendant, fewer than 2 siblings).',
    exBn: 'অধস্তন না থাকলে ও দুইয়ের কম ভাই-বোন থাকলে মাতা ১/৩ অংশ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-DAUGHTER-001',
    heirCode: 'DAUGHTER',
    condition: {
      'all': [
        {'fact': 'son.count', 'lte': 0},
        {'fact': 'daughter.count', 'equals': 1},
      ]
    },
    n: 1, d: 2, priority: 5,
    src: 'Quran 4:11',
    exEn: 'A sole daughter (no son) receives 1/2.',
    exBn: 'পুত্র না থাকলে একমাত্র কন্যা ১/২ অংশ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-DAUGHTER-002',
    heirCode: 'DAUGHTER',
    condition: {
      'all': [
        {'fact': 'son.count', 'lte': 0},
        {'fact': 'daughter.count', 'gte': 2},
      ]
    },
    n: 2, d: 3, priority: 5,
    src: 'Quran 4:11',
    exEn: 'Two or more daughters (no son) collectively receive 2/3.',
    exBn: 'পুত্র না থাকলে দুই বা ততোধিক কন্যা ২/৩ অংশ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-MSG-001',
    heirCode: 'MATERNAL_SIBLING_GROUP',
    condition: {
      'all': [
        {'fact': 'descendant.exists', 'equals': false},
        {'fact': 'father.exists', 'equals': false},
        {'fact': 'paternal_grandfather.exists', 'equals': false},
        {'fact': 'maternal_sibling.count', 'equals': 1},
      ]
    },
    n: 1, d: 6, priority: 5,
    src: 'Quran 4:12 (Kalalah)',
    exEn: 'A sole qualifying maternal sibling receives 1/6.',
    exBn: 'একক যোগ্য বৈপিত্রেয় ভাই/বোন ১/৬ অংশ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-MSG-002',
    heirCode: 'MATERNAL_SIBLING_GROUP',
    condition: {
      'all': [
        {'fact': 'descendant.exists', 'equals': false},
        {'fact': 'father.exists', 'equals': false},
        {'fact': 'paternal_grandfather.exists', 'equals': false},
        {'fact': 'maternal_sibling.count', 'gte': 2},
      ]
    },
    n: 1, d: 3, priority: 5,
    src: 'Quran 4:12 (Kalalah)',
    exEn: 'Two or more maternal siblings collectively receive 1/3 equally.',
    exBn: 'দুই বা ততোধিক বৈপিত্রেয় ভাই-বোন ১/৩ অংশ সমান পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-FS-001',
    heirCode: 'FULL_SISTER',
    condition: {'fact': 'full_sister.count', 'equals': 1},
    n: 1, d: 2, priority: 4,
    src: 'Quran 4:176',
    exEn: 'A sole full sister (no brother, no daughter) receives 1/2.',
    exBn: 'সহোদর ভাই ও কন্যা না থাকলে একমাত্র সহোদর বোন ১/২ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-FS-002',
    heirCode: 'FULL_SISTER',
    condition: {'fact': 'full_sister.count', 'gte': 2},
    n: 2, d: 3, priority: 4,
    src: 'Quran 4:176',
    exEn: 'Two or more full sisters (no brother) receive 2/3.',
    exBn: 'সহোদর ভাই না থাকলে দুই বা ততোধিক সহোদর বোন ২/৩ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-PHS-001',
    heirCode: 'PATERNAL_HALF_SISTER',
    condition: {'fact': 'paternal_half_sister.count', 'equals': 1},
    n: 1, d: 2, priority: 4,
    src: 'Hanafi fiqh',
    exEn: 'A sole paternal half-sister (no brother, no daughter) receives 1/2.',
    exBn: 'সৎ ভাই ও কন্যা না থাকলে একমাত্র সৎ বোন ১/২ পান।',
  ),
  FixedShareRule(
    id: 'BD-HANAFI-PHS-002',
    heirCode: 'PATERNAL_HALF_SISTER',
    condition: {'fact': 'paternal_half_sister.count', 'gte': 2},
    n: 2, d: 3, priority: 4,
    src: 'Hanafi fiqh',
    exEn: 'Two or more paternal half-sisters (no brother) receive 2/3.',
    exBn: 'সৎ ভাই না থাকলে দুই বা ততোধিক সৎ বোন ২/৩ পান।',
  ),
];

class BlockingRule {
  final String id;
  final String blockedHeirCode;
  final Map<String, dynamic> condition;
  final String exEn;
  final String exBn;

  const BlockingRule({
    required this.id,
    required this.blockedHeirCode,
    required this.condition,
    required this.exEn,
    required this.exBn,
  });
}

const List<BlockingRule> blockingRules = [
  BlockingRule(
    id: 'BD-HANAFI-BLOCK-001',
    blockedHeirCode: 'PATERNAL_GRANDFATHER',
    condition: {'fact': 'father.exists', 'equals': true},
    exEn: 'Father blocks the paternal grandfather.',
    exBn: 'পিতা থাকলে দাদা বঞ্চিত হন।',
  ),
  BlockingRule(
    id: 'BD-HANAFI-BLOCK-002',
    blockedHeirCode: 'FULL_SIBLING_GROUP',
    condition: {
      'any': [
        {'fact': 'son.count', 'gte': 1},
        {'fact': 'father.exists', 'equals': true},
        {
          'all': [
            {'fact': 'paternal_grandfather.exists', 'equals': true},
            {'fact': 'father.exists', 'equals': false},
          ]
        },
      ]
    },
    exEn: 'Son, father, or grandfather blocks full siblings.',
    exBn: 'পুত্র, পিতা বা দাদা থাকলে সহোদর ভাই-বোন বঞ্চিত হন।',
  ),
  BlockingRule(
    id: 'BD-HANAFI-BLOCK-003',
    blockedHeirCode: 'PATERNAL_SIBLING_GROUP',
    condition: {
      'any': [
        {'fact': 'son.count', 'gte': 1},
        {'fact': 'father.exists', 'equals': true},
        {'fact': 'full_brother.count', 'gte': 1},
        {
          'all': [
            {'fact': 'paternal_grandfather.exists', 'equals': true},
            {'fact': 'father.exists', 'equals': false},
          ]
        },
      ]
    },
    exEn: 'Son, father, grandfather, or full brother blocks paternal half-siblings.',
    exBn: 'পুত্র, পিতা, দাদা বা সহোদর ভাই থাকলে সৎ ভাই-বোন বঞ্চিত হন।',
  ),
  BlockingRule(
    id: 'BD-HANAFI-BLOCK-004',
    blockedHeirCode: 'MATERNAL_SIBLING_GROUP',
    condition: {
      'any': [
        {'fact': 'descendant.exists', 'equals': true},
        {'fact': 'father.exists', 'equals': true},
        {'fact': 'paternal_grandfather.exists', 'equals': true},
      ]
    },
    exEn: 'Descendant, father, or grandfather blocks maternal siblings.',
    exBn: 'অধস্তন, পিতা বা দাদা থাকলে বৈপিত্রেয় ভাই-বোন বঞ্চিত হন।',
  ),
  BlockingRule(
    id: 'BD-HANAFI-BLOCK-005',
    blockedHeirCode: 'PATERNAL_GRANDMOTHER',
    condition: {
      'any': [
        {'fact': 'mother.exists', 'equals': true},
        {'fact': 'father.exists', 'equals': true},
      ]
    },
    exEn: 'Mother or father blocks the paternal grandmother.',
    exBn: 'মাতা বা পিতা থাকলে দাদি বঞ্চিত হন।',
  ),
  BlockingRule(
    id: 'BD-HANAFI-BLOCK-006',
    blockedHeirCode: 'MATERNAL_GRANDMOTHER',
    condition: {'fact': 'mother.exists', 'equals': true},
    exEn: 'Mother blocks the maternal grandmother.',
    exBn: 'মাতা থাকলে নানি বঞ্চিত হন।',
  ),
];

// ============================================================================
// ৪. FAMILY MODEL
// ============================================================================
class FamilyData {
  String deceasedGender;
  int husband, wife, son, daughter;
  int predeceasedSon, predeceasedSonSurvivingGrandsons,
      predeceasedSonSurvivingGranddaughters;
  int predeceasedDaughter, predeceasedDaughterSurvivingGrandsons,
      predeceasedDaughterSurvivingGranddaughters;
  int father, mother, paternalGrandfather, paternalGrandmother,
      maternalGrandmother;
  int fullBrother, fullSister, paternalHalfBrother, paternalHalfSister;
  int maternalHalfBrother, maternalHalfSister;
  int nephewFullBrotherSon, nephewPaternalHalfBrotherSon;
  int paternalUncleFull, paternalUncleHalf;
  int cousinPaternalUncleFullSon, cousinPaternalUncleHalfSon;
  bool applyBangladeshOverride;

  FamilyData({
    this.deceasedGender = 'male',
    this.husband = 0,
    this.wife = 0,
    this.son = 0,
    this.daughter = 0,
    this.predeceasedSon = 0,
    this.predeceasedSonSurvivingGrandsons = 0,
    this.predeceasedSonSurvivingGranddaughters = 0,
    this.predeceasedDaughter = 0,
    this.predeceasedDaughterSurvivingGrandsons = 0,
    this.predeceasedDaughterSurvivingGranddaughters = 0,
    this.father = 0,
    this.mother = 0,
    this.paternalGrandfather = 0,
    this.paternalGrandmother = 0,
    this.maternalGrandmother = 0,
    this.fullBrother = 0,
    this.fullSister = 0,
    this.paternalHalfBrother = 0,
    this.paternalHalfSister = 0,
    this.maternalHalfBrother = 0,
    this.maternalHalfSister = 0,
    this.nephewFullBrotherSon = 0,
    this.nephewPaternalHalfBrotherSon = 0,
    this.paternalUncleFull = 0,
    this.paternalUncleHalf = 0,
    this.cousinPaternalUncleFullSon = 0,
    this.cousinPaternalUncleHalfSon = 0,
    this.applyBangladeshOverride = true,
  });

  Map<String, dynamic> buildFacts() {
    final hasDirectDescendant = son > 0 || daughter > 0;
    final hasBdSubstitute = applyBangladeshOverride &&
        (predeceasedSon > 0 || predeceasedDaughter > 0) &&
        (predeceasedSonSurvivingGrandsons +
                predeceasedSonSurvivingGranddaughters +
                predeceasedDaughterSurvivingGrandsons +
                predeceasedDaughterSurvivingGranddaughters) >
            0;
    final descendantExists = hasDirectDescendant || hasBdSubstitute;
    final fullSiblingCount = fullBrother + fullSister;
    final paternalSiblingCount = paternalHalfBrother + paternalHalfSister;
    final maternalSiblingCount = maternalHalfBrother + maternalHalfSister;

    return {
      'descendant.exists': descendantExists,
      'son.count': son,
      'daughter.count': daughter,
      'father.exists': father > 0,
      'mother.exists': mother > 0,
      'paternal_grandfather.exists': paternalGrandfather > 0,
      'full_brother.count': fullBrother,
      'full_sister.count': fullSister,
      'paternal_half_brother.count': paternalHalfBrother,
      'paternal_half_sister.count': paternalHalfSister,
      'paternal_sibling.count': paternalSiblingCount,
      'maternal_sibling.count': maternalSiblingCount,
      'sibling.count': fullSiblingCount + paternalSiblingCount + maternalSiblingCount,
    };
  }
}

// ============================================================================
// ৫. HEIR RESULT
// ============================================================================
class HeirResult {
  final String heirCode;
  final String label;
  final int count;
  Fraction share;
  final bool isAsabah;
  final String ruleId;
  final String exEn;
  final String exBn;
  // Asset amounts (per asset key: total, perPerson)
  final Map<String, Map<String, double>> amounts;

  HeirResult({
    required this.heirCode,
    required this.label,
    required this.count,
    required this.share,
    this.isAsabah = false,
    required this.ruleId,
    required this.exEn,
    required this.exBn,
    this.amounts = const {},
  });
}

class BlockedHeir {
  final String heirCode;
  final String reason;
  final String reasonBn;
  final String ruleId;

  BlockedHeir({
    required this.heirCode,
    required this.reason,
    required this.reasonBn,
    required this.ruleId,
  });
}

class FarayezResult {
  final String status;
  final String? reason;
  final List<HeirResult> heirs;
  final List<BlockedHeir> blockedHeirs;
  final bool awlApplied;
  final bool raddApplied;
  final bool bangladeshOverrideApplied;
  final String profileId;
  // Assets used (raw values)
  final Map<String, double> assets;

  FarayezResult({
    required this.status,
    this.reason,
    this.heirs = const [],
    this.blockedHeirs = const [],
    this.awlApplied = false,
    this.raddApplied = false,
    this.bangladeshOverrideApplied = false,
    this.profileId = PROFILE_ID,
    this.assets = const {},
  });
}

// ============================================================================
// ৬. ENGINE
// ============================================================================
bool evaluateCondition(Map<String, dynamic> cond, Map<String, dynamic> facts) {
  if (cond.containsKey('all')) {
    return (cond['all'] as List)
        .every((c) => evaluateCondition(c as Map<String, dynamic>, facts));
  }
  if (cond.containsKey('any')) {
    return (cond['any'] as List)
        .any((c) => evaluateCondition(c as Map<String, dynamic>, facts));
  }
  if (cond.containsKey('none')) {
    return !(cond['none'] as List)
        .any((c) => evaluateCondition(c as Map<String, dynamic>, facts));
  }
  final val = facts[cond['fact']];
  if (cond.containsKey('equals')) return val == cond['equals'];
  if (cond.containsKey('gte')) {
    return val is num && val >= cond['gte'];
  }
  if (cond.containsKey('lte')) {
    return val is num && val <= cond['lte'];
  }
  if (cond.containsKey('gt')) {
    return val is num && val > cond['gt'];
  }
  if (cond.containsKey('lt')) {
    return val is num && val < cond['lt'];
  }
  return false;
}

HeirResult _mk(String code, String label, int count, Fraction share,
    String ruleId, String exEn, String exBn, bool isAsabah) {
  return HeirResult(
    heirCode: code,
    label: label,
    count: count,
    share: share,
    ruleId: ruleId,
    exEn: exEn,
    exBn: exBn,
    isAsabah: isAsabah,
  );
}

class _AsabahResult {
  final List<HeirResult> assigned;
  final List<String> events;
  _AsabahResult(this.assigned, this.events);
}

_AsabahResult _calculateAsabah(
  FamilyData f,
  Fraction residue,
  Set<String> blocked,
  bool fatherHasFixed,
) {
  final assigned = <HeirResult>[];
  final events = <String>[];
  if (residue.isZero() || residue.lt(Fraction.zero())) {
    return _AsabahResult(assigned, events);
  }
  final bdSon = f.applyBangladeshOverride &&
      f.predeceasedSon > 0 &&
      (f.predeceasedSonSurvivingGrandsons +
              f.predeceasedSonSurvivingGranddaughters) >
          0;
  final bdDaughter = f.applyBangladeshOverride &&
      f.predeceasedDaughter > 0 &&
      (f.predeceasedDaughterSurvivingGrandsons +
              f.predeceasedDaughterSurvivingGranddaughters) >
          0;

  if (f.son > 0 || bdSon || bdDaughter) {
    final sonUnits = f.son * 2;
    final daughterUnits = f.daughter;
    final bdSonUnit = bdSon ? 2 : 0;
    final bdDaughterUnit = bdDaughter ? 1 : 0;
    final totalUnits = sonUnits + daughterUnits + bdSonUnit + bdDaughterUnit;
    final unitVal = residue.div(Fraction.fromInt(totalUnits));

    if (f.son > 0) {
      assigned.add(_mk('SON', 'পুত্র', f.son, unitVal.scaleInt(2 * f.son),
          'HANAFI-ASABAH-SON', 'Sons take residue 2:1 with daughters.',
          'পুত্র সহোদর কন্যার সাথে ২:১ অনুপাতে অবশিষ্টাংশ পান।', true));
    }
    if (f.daughter > 0) {
      assigned.add(_mk('DAUGHTER_ASABAH', 'কন্যা (আসাবা)', f.daughter,
          unitVal.scaleInt(f.daughter), 'HANAFI-ASABAH-DAUGHTER',
          'Daughters share residue with sons 1:2.',
          'কন্যা পুত্রের সাথে ১:২ অনুপাতে অবশিষ্টাংশ পান।', true));
    }
    if (bdSon) {
      events.add('BD_OVERRIDE_APPLIED');
      final share = unitVal.scaleInt(2);
      final gUnits = f.predeceasedSonSurvivingGrandsons * 2 +
          f.predeceasedSonSurvivingGranddaughters;
      if (gUnits > 0) {
        final gUnitVal = share.div(Fraction.fromInt(gUnits));
        if (f.predeceasedSonSurvivingGrandsons > 0) {
          assigned.add(_mk(
              'SON_SON_BD',
              'পুত্রের পুত্র (বাংলাদেশ আইন)',
              f.predeceasedSonSurvivingGrandsons,
              gUnitVal.scaleInt(2 * f.predeceasedSonSurvivingGrandsons),
              'BD-MFLO-1961-S4',
              'Bangladesh statutory rule applied (MFLO 1961 s.4).',
              'বাংলাদেশ পারিবারিক আইন অধ্যাদেশ ১৯৬১, ধারা ৪ প্রয়োগ।',
              true));
        }
        if (f.predeceasedSonSurvivingGranddaughters > 0) {
          assigned.add(_mk(
              'SON_DAUGHTER_BD',
              'পুত্রের কন্যা (বাংলাদেশ আইন)',
              f.predeceasedSonSurvivingGranddaughters,
              gUnitVal.scaleInt(f.predeceasedSonSurvivingGranddaughters),
              'BD-MFLO-1961-S4',
              'Bangladesh statutory rule applied (MFLO 1961 s.4).',
              'বাংলাদেশ পারিবারিক আইন অধ্যাদেশ ১৯৬১, ধারা ৪ প্রয়োগ।',
              true));
        }
      }
    }
    if (bdDaughter) {
      events.add('BD_OVERRIDE_APPLIED');
      final share = unitVal.scaleInt(1);
      final gUnits = f.predeceasedDaughterSurvivingGrandsons * 2 +
          f.predeceasedDaughterSurvivingGranddaughters;
      if (gUnits > 0) {
        final gUnitVal = share.div(Fraction.fromInt(gUnits));
        if (f.predeceasedDaughterSurvivingGrandsons > 0) {
          assigned.add(_mk(
              'DAUGHTER_SON_BD',
              'কন্যার পুত্র (বাংলাদেশ আইন)',
              f.predeceasedDaughterSurvivingGrandsons,
              gUnitVal.scaleInt(2 * f.predeceasedDaughterSurvivingGrandsons),
              'BD-MFLO-1961-S4',
              'Bangladesh statutory rule applied (MFLO 1961 s.4).',
              'বাংলাদেশ পারিবারিক আইন অধ্যাদেশ ১৯৬১, ধারা ৪ প্রয়োগ।',
              true));
        }
        if (f.predeceasedDaughterSurvivingGranddaughters > 0) {
          assigned.add(_mk(
              'DAUGHTER_DAUGHTER_BD',
              'কন্যার কন্যা (বাংলাদেশ আইন)',
              f.predeceasedDaughterSurvivingGranddaughters,
              gUnitVal.scaleInt(
                  f.predeceasedDaughterSurvivingGranddaughters),
              'BD-MFLO-1961-S4',
              'Bangladesh statutory rule applied (MFLO 1961 s.4).',
              'বাংলাদেশ পারিবারিক আইন অধ্যাদেশ ১৯৬১, ধারা ৪ প্রয়োগ।',
              true));
        }
      }
    }
    return _AsabahResult(assigned, events);
  }

  if (f.father > 0 && !blocked.contains('FATHER')) {
    assigned.add(_mk(
        'FATHER_ASABAH',
        fatherHasFixed ? 'পিতা (অবশিষ্ট)' : 'পিতা (আসাবা)',
        1,
        residue,
        'HANAFI-ASABAH-FATHER',
        'Father takes residue as asabah.',
        'পিতা অবশিষ্টাংশ আসাবা হিসেবে পান।',
        true));
    return _AsabahResult(assigned, events);
  }

  if (f.paternalGrandfather > 0 &&
      f.father == 0 &&
      !blocked.contains('PATERNAL_GRANDFATHER')) {
    assigned.add(_mk('GRANDFATHER_ASABAH', 'দাদা (আসাবা)', 1, residue,
        'HANAFI-ASABAH-GRANDFATHER', 'Paternal grandfather takes residue.',
        'পিতা না থাকলে দাদা অবশিষ্টাংশ পান।', true));
    return _AsabahResult(assigned, events);
  }

  if (!blocked.contains('FULL_SIBLING_GROUP') && f.fullBrother > 0) {
    final units = f.fullBrother * 2 + f.fullSister;
    final unitVal = residue.div(Fraction.fromInt(units));
    assigned.add(_mk('FULL_BROTHER', 'সহোদর ভাই', f.fullBrother,
        unitVal.scaleInt(2 * f.fullBrother), 'HANAFI-ASABAH-FB',
        'Full brothers take residue 2:1 with full sisters.',
        'সহোদর ভাই সহোদর বোনের সাথে ২:১ অনুপাতে পান।', true));
    if (f.fullSister > 0) {
      assigned.add(_mk('FULL_SISTER_ASABAH', 'সহোদর বোন (আসাবা)',
          f.fullSister, unitVal.scaleInt(f.fullSister),
          'HANAFI-ASABAH-FS', 'Full sisters share 1:2.',
          'সহোদর বোন ভাইয়ের সাথে ১:২ অনুপাতে পান।', true));
    }
    return _AsabahResult(assigned, events);
  }

  if (!blocked.contains('FULL_SIBLING_GROUP') &&
      f.fullBrother == 0 &&
      f.fullSister > 0 &&
      f.daughter > 0) {
    assigned.add(_mk(
        'FULL_SISTER_GHAYR',
        'সহোদর বোন (আসাবা মা\'আল গায়ের)',
        f.fullSister,
        residue,
        'HANAFI-ASABAH-FS-GHAYR',
        'Full sisters become residuary with daughters.',
        'কন্যার সাথে সহোদর বোন আসাবা মা\'আল গায়ের হন।',
        true));
    return _AsabahResult(assigned, events);
  }

  if (!blocked.contains('PATERNAL_SIBLING_GROUP') && f.paternalHalfBrother > 0) {
    final units = f.paternalHalfBrother * 2 + f.paternalHalfSister;
    final unitVal = residue.div(Fraction.fromInt(units));
    assigned.add(_mk('PHB', 'সৎ ভাই (বৈমাত্রেয়)', f.paternalHalfBrother,
        unitVal.scaleInt(2 * f.paternalHalfBrother), 'HANAFI-ASABAH-PHB',
        'Paternal half-brothers take residue 2:1.',
        'সৎ ভাই ২:১ অনুপাতে পান।', true));
    if (f.paternalHalfSister > 0) {
      assigned.add(_mk('PHS_ASABAH', 'সৎ বোন (আসাবা)',
          f.paternalHalfSister, unitVal.scaleInt(f.paternalHalfSister),
          'HANAFI-ASABAH-PHS', 'Paternal half-sisters share 1:2.',
          'সৎ বোন ১:২ অনুপাতে পান।', true));
    }
    return _AsabahResult(assigned, events);
  }

  // Extended tiers
  final tiers = [
    [f.nephewFullBrotherSon, 'NEPHEW_FULL', 'ভাতিজা (সহোদর ভাইয়ের পুত্র)'],
    [f.nephewPaternalHalfBrotherSon, 'NEPHEW_HALF', 'ভাতিজা (সৎ ভাইয়ের পুত্র)'],
    [f.paternalUncleFull, 'UNCLE_FULL', 'চাচা'],
    [f.paternalUncleHalf, 'UNCLE_HALF', 'চাচা (বৈমাত্রেয়)'],
    [f.cousinPaternalUncleFullSon, 'COUSIN_FULL', 'চাচাতো ভাই'],
    [f.cousinPaternalUncleHalfSon, 'COUSIN_HALF', 'চাচাতো ভাই (বৈমাত্রেয়)'],
  ];
  if (!blocked.contains('NEPHEW_UNCLE_COUSIN_GROUP')) {
    for (final t in tiers) {
      final count = t[0] as int;
      if (count > 0) {
        assigned.add(_mk(t[1] as String, t[2] as String, count, residue,
            'HANAFI-ASABAH-EXT', 'Extended agnatic tier.',
            'সম্প্রসারিত আসাবা স্তর।', true));
        return _AsabahResult(assigned, events);
      }
    }
  }
  return _AsabahResult(assigned, events);
}

FarayezResult calculateInheritance(
    FamilyData family, Map<String, double> assets) {
  if (family.husband > 0 && family.wife > 0) {
    return FarayezResult(
      status: 'EXPERT_REVIEW_REQUIRED',
      reason: 'একজন মৃত ব্যক্তির একই সাথে স্বামী ও স্ত্রী উভয়ই থাকতে পারে না।',
    );
  }

  final facts = family.buildFacts();
  final blockedMap = <String, List<BlockedHeir>>{};
  for (final rule in blockingRules) {
    if (evaluateCondition(rule.condition, facts)) {
      blockedMap.putIfAbsent(rule.blockedHeirCode, () => []);
      blockedMap[rule.blockedHeirCode]!.add(BlockedHeir(
        heirCode: rule.blockedHeirCode,
        reason: rule.exEn,
        reasonBn: rule.exBn,
        ruleId: rule.id,
      ));
    }
  }
  final blockedCodes = blockedMap.keys.toSet();

  // Present heirs
  final presentHeirs = <Map<String, dynamic>>[];
  if (family.deceasedGender == 'male' && family.wife > 0) {
    presentHeirs.add({'code': 'WIFE', 'label': 'স্ত্রী', 'count': family.wife});
  }
  if (family.deceasedGender == 'female' && family.husband > 0) {
    presentHeirs
        .add({'code': 'HUSBAND', 'label': 'স্বামী', 'count': family.husband});
  }
  if (family.father > 0) {
    presentHeirs.add({'code': 'FATHER', 'label': 'পিতা', 'count': family.father});
  }
  if (family.mother > 0) {
    presentHeirs.add({'code': 'MOTHER', 'label': 'মাতা', 'count': family.mother});
  }
  if (family.daughter > 0) {
    presentHeirs
        .add({'code': 'DAUGHTER', 'label': 'কন্যা', 'count': family.daughter});
  }
  final msgCount =
      family.maternalHalfBrother + family.maternalHalfSister;
  if (msgCount > 0) {
    presentHeirs.add({
      'code': 'MATERNAL_SIBLING_GROUP',
      'label': 'বৈপিত্রেয় ভাই-বোন',
      'count': msgCount,
    });
  }

  if (family.fullBrother == 0 &&
      family.fullSister > 0 &&
      family.daughter == 0 &&
      !blockedCodes.contains('FULL_SIBLING_GROUP')) {
    presentHeirs.add(
        {'code': 'FULL_SISTER', 'label': 'সহোদর বোন', 'count': family.fullSister});
  }
  if (family.paternalHalfBrother == 0 &&
      family.paternalHalfSister > 0 &&
      family.daughter == 0 &&
      !blockedCodes.contains('PATERNAL_SIBLING_GROUP')) {
    presentHeirs.add({
      'code': 'PATERNAL_HALF_SISTER',
      'label': 'সৎ বোন (বৈমাত্রেয়)',
      'count': family.paternalHalfSister
    });
  }

  // Fixed shares
  final fixedHeirs = <HeirResult>[];
  for (final heir in presentHeirs) {
    final count = heir['count'] as int;
    final code = heir['code'] as String;
    final label = heir['label'] as String;
    if (count <= 0 || blockedCodes.contains(code)) continue;
    final candidates = fixedShareRules
        .where((r) =>
            r.heirCode == code && evaluateCondition(r.condition, facts))
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    if (candidates.isEmpty) continue;
    final r = candidates.first;
    fixedHeirs.add(
        _mk(code, label, count, Fraction(BigInt.from(r.n), BigInt.from(r.d)),
            r.id, r.exEn, r.exBn, false));
  }

  var fixedTotal = sumFractions(fixedHeirs.map((h) => h.share).toList());
  var awlApplied = false, raddApplied = false;
  var bangladeshOverrideApplied = false;
  var allHeirs = List<HeirResult>.from(fixedHeirs);
  var residue = Fraction.one().sub(fixedTotal);

  if (fixedTotal.gt(Fraction.one())) {
    for (final h in allHeirs) {
      h.share = h.share.div(fixedTotal);
    }
    awlApplied = true;
    residue = Fraction.zero();
  } else {
    final fatherHasFixed = fixedHeirs.any((h) => h.heirCode == 'FATHER');
    final asabahResult =
        _calculateAsabah(family, residue, blockedCodes, fatherHasFixed);
    if (asabahResult.events.contains('BD_OVERRIDE_APPLIED')) {
      bangladeshOverrideApplied = true;
    }
    allHeirs = [...allHeirs, ...asabahResult.assigned];
    residue = residue.sub(
        sumFractions(asabahResult.assigned.map((h) => h.share).toList()));

    if (residue.gt(Fraction.zero()) &&
        asabahResult.assigned.isEmpty &&
        allHeirs.isNotEmpty) {
      final pool = allHeirs
          .where((h) => h.heirCode != 'WIFE' && h.heirCode != 'HUSBAND')
          .toList();
      if (pool.isNotEmpty) {
        final poolSum = sumFractions(pool.map((h) => h.share).toList());
        if (!poolSum.isZero()) {
          for (final h in pool) {
            h.share = h.share.add(residue.mul(h.share.div(poolSum)));
          }
          raddApplied = true;
          residue = Fraction.zero();
        }
      }
    }
  }

  if (allHeirs.isEmpty) {
    return FarayezResult(
      status: 'EXPERT_REVIEW_REQUIRED',
      reason: 'কোনো ওয়ারিশের তথ্য দেওয়া হয়নি।',
    );
  }

  final totalShares =
      sumFractions(allHeirs.map((h) => h.share).toList());
  final reconciles = (totalShares.sub(Fraction.one())).num == BigInt.zero;
  if (!reconciles) {
    return FarayezResult(
      status: 'EXPERT_REVIEW_REQUIRED',
      reason:
          'এই configuration-এর জন্য automated calculation নিশ্চিতভাবে করা যাচ্ছে না (যেমন: একমাত্র স্বামী/স্ত্রী, যেখানে দূরবর্তী আত্মীয়/সরকারি কোষাগার নিয়ম প্রযোজ্য)।',
    );
  }

  final blockedList = blockedMap.values.expand((e) => e).toList();

  // Compute per-asset amounts
  final heirsWithAmounts = allHeirs.map((h) {
    final shareNum = h.share.toNumber();
    final amounts = <String, Map<String, double>>{};
    for (final key in assetKeys) {
      final total = shareNum * (assets[key] ?? 0);
      amounts[key] = {
        'total': total,
        'perPerson': total / (h.count > 0 ? h.count : 1),
      };
    }
    return HeirResult(
      heirCode: h.heirCode,
      label: h.label,
      count: h.count,
      share: h.share,
      isAsabah: h.isAsabah,
      ruleId: h.ruleId,
      exEn: h.exEn,
      exBn: h.exBn,
      amounts: amounts,
    );
  }).toList();

  return FarayezResult(
    status: 'OK',
    heirs: heirsWithAmounts,
    blockedHeirs: blockedList,
    awlApplied: awlApplied,
    raddApplied: raddApplied,
    bangladeshOverrideApplied: bangladeshOverrideApplied,
    assets: assets,
  );
}

// ============================================================================
// ৭. MAIN WIDGET (Standalone)
// ============================================================================
class FarayezCalculator extends StatefulWidget {
  const FarayezCalculator({super.key});

  @override
  State<FarayezCalculator> createState() => _FarayezCalculatorState();
}

class _FarayezCalculatorState extends State<FarayezCalculator> {
  int _step = 1;
  String _gender = 'male';
  // Assets as strings (for TextField)
  final Map<String, String> _assetInputs = {'land': '', 'gold': '', 'cash': ''};
  FamilyData _family = FamilyData();
  FarayezResult? _result;

  static const _emeraldDark = Color(0xFF0B5D36);
  static const _emerald = Color(0xFF10B981);

  void _setField(String key, int v) {
    setState(() {
      switch (key) {
        case 'wife': _family.wife = v; break;
        case 'husband': _family.husband = v; break;
        case 'son': _family.son = v; break;
        case 'daughter': _family.daughter = v; break;
        case 'predeceasedSon': _family.predeceasedSon = v; break;
        case 'predeceasedSonSurvivingGrandsons':
          _family.predeceasedSonSurvivingGrandsons = v; break;
        case 'predeceasedSonSurvivingGranddaughters':
          _family.predeceasedSonSurvivingGranddaughters = v; break;
        case 'father': _family.father = v; break;
        case 'mother': _family.mother = v; break;
        case 'paternalGrandfather': _family.paternalGrandfather = v; break;
        case 'fullBrother': _family.fullBrother = v; break;
        case 'fullSister': _family.fullSister = v; break;
        case 'paternalHalfBrother': _family.paternalHalfBrother = v; break;
        case 'paternalHalfSister': _family.paternalHalfSister = v; break;
        case 'maternalHalfBrother': _family.maternalHalfBrother = v; break;
        case 'maternalHalfSister': _family.maternalHalfSister = v; break;
      }
    });
  }

  bool get _hasAnyAsset =>
      assetKeys.any((k) => parseAmount(_assetInputs[k] ?? '') > 0);

  void _runCalculation() {
    final numericAssets = <String, double>{};
    for (final k in assetKeys) {
      numericAssets[k] = parseAmount(_assetInputs[k] ?? '');
    }
    final r = calculateInheritance(_family, numericAssets);
    setState(() {
      _result = r;
      _step = 4;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildStepperIndicator(),
          const SizedBox(height: 16),
          if (_step == 1) _buildStep1(),
          if (_step == 2) _buildStep2(),
          if (_step == 3) _buildStep3(),
          if (_step == 4 && _result != null) _buildStep4(),
        ],
      ),
    );
  }

  // ============ HEADER ============
  Widget _buildHeader() {
    return Column(
      children: [
        Text('UKIL',
            style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _emeraldDark,
                letterSpacing: 2)),
        const SizedBox(height: 4),
        Text('উকিল ফারায়েজ',
            style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A))),
        const SizedBox(height: 4),
        Text('উত্তরাধিকার বণ্টন বুঝুন, হিসাব করুন, বিশেষজ্ঞের পরামর্শ নিন।',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
                fontSize: 11, color: const Color(0xFF64748B))),
      ],
    );
  }

  // ============ STEPPER INDICATOR ============
  Widget _buildStepperIndicator() {
    final steps = ['মৃত ব্যক্তি', 'সম্পত্তি', 'পরিবার', 'ফলাফল'];
    return Row(
      children: List.generate(steps.length, (i) {
        final active = _step == i + 1;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: active ? _emeraldDark : const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
            ),
            child: Text('${i + 1}. ${steps[i]}',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 10,
                    color: active ? _emeraldDark : const Color(0xFF94A3B8),
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ),
        );
      }),
    );
  }

  // ============ STEP 1: DECEASED ============
  Widget _buildStep1() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('মৃত ব্যক্তির তথ্য',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text('লিঙ্গ:', style: GoogleFonts.inter(fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _gender,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            ),
            items: const [
              DropdownMenuItem(value: 'male', child: Text('পুরুষ (Male)')),
              DropdownMenuItem(value: 'female', child: Text('মহিলা (Female)')),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _gender = v;
                _family = FamilyData(deceasedGender: v);
              });
            },
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                      text: 'Calculation Profile: ',
                      style: GoogleFonts.inter(fontSize: 11)),
                  TextSpan(
                      text:
                          'Bangladesh Muslim Inheritance — Sunni/Hanafi + প্রযোজ্য বাংলাদেশ সংবিধিবদ্ধ বিধান',
                      style: GoogleFonts.inter(
                          fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _primaryButton('পরবর্তী →', () => setState(() => _step = 2)),
        ],
      ),
    );
  }

  // ============ STEP 2: ESTATE (ASSETS) ============
  Widget _buildStep2() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('বণ্টনযোগ্য সম্পত্তি',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
              'ঋণ, দাফন খরচ ও বৈধ ওসিয়ত বাদ দেওয়ার পর অবশিষ্ট পরিমাণ দিন। যে সম্পত্তি নেই তা ফাঁকা রাখুন।',
              style: GoogleFonts.inter(
                  fontSize: 11, color: const Color(0xFF64748B))),
          const SizedBox(height: 12),
          ...assetMetaList.map((meta) => _assetInput(meta)),
          if (!_hasAnyAsset)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: Text(
                'কমপক্ষে একটি সম্পত্তির পরিমাণ দিন (জমি, স্বর্ণ বা টাকা)।',
                style: GoogleFonts.inter(
                    fontSize: 11, color: const Color(0xFF92400E)),
              ),
            ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _outlinedButton(
                  '← পূর্বে', () => setState(() => _step = 1)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: _hasAnyAsset
                    ? () => setState(() => _step = 3)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _emeraldDark,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFCBD5E1),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('পরবর্তী →',
                    style: GoogleFonts.inter(
                        fontSize: 14, fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _assetInput(AssetMeta meta) {
    final value = _assetInputs[meta.key] ?? '';
    final active = parseAmount(value) > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: active ? _emerald : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${meta.icon} ${meta.label}',
                  style: GoogleFonts.inter(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              Text('(${meta.unit})',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: meta.hint,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              isDense: true,
            ),
            controller: TextEditingController(text: value)
              ..selection = TextSelection.collapsed(offset: value.length),
            onChanged: (v) {
              setState(() => _assetInputs[meta.key] = v);
            },
          ),
        ],
      ),
    );
  }

  // ============ STEP 3: FAMILY ============
  Widget _buildStep3() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('১. স্বামী/স্ত্রী ও সন্তান'),
          _grid([
            if (_gender == 'male')
              _stepper('স্ত্রী', _family.wife, (v) => _setField('wife', v)),
            if (_gender == 'female')
              _stepper('স্বামী', _family.husband,
                  (v) => _setField('husband', v)),
            _stepper('পুত্র', _family.son, (v) => _setField('son', v)),
            _stepper('কন্যা', _family.daughter,
                (v) => _setField('daughter', v)),
          ]),
          const SizedBox(height: 12),
          _sectionTitle('বাংলাদেশ ধারা ৪ (প্রয়াত সন্তান)'),
          _grid([
            _stepper('প্রয়াত পুত্র', _family.predeceasedSon,
                (v) => _setField('predeceasedSon', v)),
            _stepper('তার পুত্র', _family.predeceasedSonSurvivingGrandsons,
                (v) =>
                    _setField('predeceasedSonSurvivingGrandsons', v)),
            _stepper(
                'তার কন্যা',
                _family.predeceasedSonSurvivingGranddaughters,
                (v) =>
                    _setField('predeceasedSonSurvivingGranddaughters', v)),
          ]),
          const SizedBox(height: 12),
          _sectionTitle('২. পিতা-মাতা ও ঊর্ধ্বতন'),
          _grid([
            _stepper('পিতা', _family.father, (v) => _setField('father', v)),
            _stepper('মাতা', _family.mother, (v) => _setField('mother', v)),
            _stepper('দাদা', _family.paternalGrandfather,
                (v) => _setField('paternalGrandfather', v)),
          ]),
          const SizedBox(height: 12),
          _sectionTitle('৩. ভাই-বোন'),
          _grid([
            _stepper('সহোদর ভাই', _family.fullBrother,
                (v) => _setField('fullBrother', v)),
            _stepper('সহোদর বোন', _family.fullSister,
                (v) => _setField('fullSister', v)),
            _stepper('সৎ ভাই', _family.paternalHalfBrother,
                (v) => _setField('paternalHalfBrother', v)),
            _stepper('সৎ বোন', _family.paternalHalfSister,
                (v) => _setField('paternalHalfSister', v)),
            _stepper('বৈপিত্রেয় ভাই', _family.maternalHalfBrother,
                (v) => _setField('maternalHalfBrother', v)),
            _stepper('বৈপিত্রেয় বোন', _family.maternalHalfSister,
                (v) => _setField('maternalHalfSister', v)),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: _outlinedButton(
                  '← পূর্বে', () => setState(() => _step = 2)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _primaryButton('⚖️ হিসাব করুন', _runCalculation),
            ),
          ]),
        ],
      ),
    );
  }

  // ============ STEP 4: RESULT ============
  Widget _buildStep4() {
    final r = _result!;
    if (r.status == 'EXPERT_REVIEW_REQUIRED') {
      return _card(
        child: Column(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 8),
            Text('বিশেষজ্ঞ যাচাই প্রয়োজন',
                style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB45309))),
            const SizedBox(height: 8),
            Text(r.reason ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 13, color: const Color(0xFF475569))),
            const SizedBox(height: 16),
            _primaryButton('← পরিবার সম্পাদনা করুন',
                () => setState(() => _step = 3)),
          ],
        ),
      );
    }

    // Active asset keys (only those with value > 0)
    final activeAssetKeys = assetKeys
        .where((k) => (r.assets[k] ?? 0) > 0)
        .toList();

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ফলাফল (বণ্টন নামা)',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          if (r.bangladeshOverrideApplied)
            _infoBanner(
                'বাংলাদেশ statutory succession rule applied (MFLO 1961, s.4). Classical Faraid calculation may differ.',
                const Color(0xFFEFF6FF),
                const Color(0xFF1E40AF)),
          if (r.awlApplied)
            _infoBanner(
                'আউল (Awl) প্রয়োগ করা হয়েছে — নির্ধারিত অংশসমূহ আনুপাতিক হারে সমন্বয় করা হয়েছে।',
                const Color(0xFFFFFBEB),
                const Color(0xFF92400E)),
          if (r.raddApplied)
            _infoBanner(
                'রদ্দ (Radd) প্রয়োগ করা হয়েছে — অবশিষ্ট অংশ আনুপাতিক হারে ফেরত দেওয়া হয়েছে।',
                const Color(0xFFEFF6FF),
                const Color(0xFF1E40AF)),

          // Total distributable assets summary
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('মোট বণ্টনযোগ্য সম্পত্তি',
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF475569))),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: activeAssetKeys.map((k) {
                    final meta =
                        assetMetaList.firstWhere((m) => m.key == k);
                    return Text('${meta.icon} ${formatAmount(k, r.assets[k] ?? 0)}',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A)));
                  }).toList(),
                ),
              ],
            ),
          ),

          // Heirs list
          ...r.heirs.map((h) => _heirCard(h, activeAssetKeys)),

          if (r.blockedHeirs.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('বঞ্চিত (Blocked)',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF475569))),
            const SizedBox(height: 6),
            ...r.blockedHeirs.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: '✕ '),
                      TextSpan(text: '${b.heirCode} — '),
                      TextSpan(
                          text: b.reasonBn,
                          style:
                              const TextStyle(color: Color(0xFF64748B))),
                      TextSpan(
                          text: '  (${b.ruleId})',
                          style: const TextStyle(
                              fontSize: 10, color: Color(0xFF94A3B8))),
                    ]),
                    style: GoogleFonts.inter(
                        fontSize: 11, color: const Color(0xFFDC2626)),
                  ),
                )),
          ],

          const SizedBox(height: 16),
          const Divider(),
          Text(
            'এই calculator একটি তথ্যভিত্তিক সহায়ক tool। চূড়ান্ত সিদ্ধান্তের আগে যোগ্য আইনজীবীর পরামর্শ নিন। Rule profile: ${r.profileId}',
            style: GoogleFonts.inter(
                fontSize: 10, color: const Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          _outlinedButton(
              '← পরিবার সম্পাদনা করুন', () => setState(() => _step = 3)),
        ],
      ),
    );
  }

  // Individual heir card (React-এর মত: share + per-asset amounts)
  Widget _heirCard(HeirResult h, List<String> activeAssetKeys) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${h.label}${h.count > 1 ? " (${h.count} জন)" : ""}',
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A)),
                ),
              ),
              Text(
                '${h.share.toString()} = ${h.share.toPercent()}',
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: activeAssetKeys.map((k) {
              final meta = assetMetaList.firstWhere((m) => m.key == k);
              final amt = h.amounts[k] ?? {'perPerson': 0.0, 'total': 0.0};
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${meta.icon} ${meta.label}${h.count > 1 ? " (প্রতি জন)" : ""}',
                      style: GoogleFonts.inter(
                          fontSize: 9, color: const Color(0xFF64748B)),
                    ),
                    Text(
                      formatAmount(k, amt['perPerson'] ?? 0),
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _emeraldDark),
                    ),
                    if (h.count > 1)
                      Text(
                        'মোট ${formatAmount(k, amt['total'] ?? 0)}',
                        style: GoogleFonts.inter(
                            fontSize: 9, color: const Color(0xFF94A3B8)),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ============ HELPERS ============
  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: child,
      );

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF334155))),
      );

  Widget _grid(List<Widget> children) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.4,
        children: children,
      );

  Widget _stepper(String label, int value, ValueChanged<int> onChange) {
    final active = value > 0;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFECFDF5) : Colors.white,
        border: Border.all(
            color: active ? _emerald : const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155))),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stepperBtn('−', const Color(0xFFF1F5F9),
                  const Color(0xFF334155), () {
                if (value > 0) onChange(value - 1);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text('$value',
                    style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              _stepperBtn('+', const Color(0xFFD1FAE5), _emeraldDark,
                  () => onChange(value + 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepperBtn(
      String txt, Color bg, Color fg, VoidCallback onTap) =>
    InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(txt,
            style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.bold, color: fg)),
      ),
    );

  Widget _primaryButton(String txt, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _emeraldDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(txt,
              style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _outlinedButton(String txt, VoidCallback onTap) => SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF334155),
            padding: const EdgeInsets.symmetric(vertical: 14),
            side: const BorderSide(color: Color(0xFFCBD5E1)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(txt,
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      );

  Widget _infoBanner(String text, Color bg, Color fg) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: fg.withOpacity(0.2)),
        ),
        child: Text(text,
            style: GoogleFonts.inter(fontSize: 11, color: fg)),
      );
}