import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum AdvocateSpeciality {
  CRIMINAL_LAWYER,
  CIVIL_LAWYER,
  FAMILY_LAWYER,
  CORPORATE_LAWYER,
  CYBER_CRIME_LAWYER,
  PROPERTY_LAWYER,
  INTELLECTUAL_PROPERTY_LAWYER,
  TAX_LAWYER,
  LABOR_LAWYER,
  TRADE_LAWYER,
  BANKING_LAWYER,
  INSURANCE_LAWYER,
  WOMEN_AND_CHILD_RIGHTS_LAWYER,
}

extension AdvocateSpecialityExt on AdvocateSpeciality {
  String get apiValue => name; // EXACT enum string

  static AdvocateSpeciality fromApi(String value) {
    return AdvocateSpeciality.values.firstWhere(
          (e) => e.name == value,
      orElse: () => AdvocateSpeciality.CRIMINAL_LAWYER,
    );
  }

  String get label {
    switch (this) {
      case AdvocateSpeciality.CRIMINAL_LAWYER:
        return "Criminal Lawyer";
      case AdvocateSpeciality.CIVIL_LAWYER:
        return "Civil Lawyer";
      case AdvocateSpeciality.FAMILY_LAWYER:
        return "Family Lawyer";
      case AdvocateSpeciality.CORPORATE_LAWYER:
        return "Corporate Lawyer";
      case AdvocateSpeciality.CYBER_CRIME_LAWYER:
        return "Cyber Crime Lawyer";
      case AdvocateSpeciality.PROPERTY_LAWYER:
        return "Property Lawyer";
      case AdvocateSpeciality.INTELLECTUAL_PROPERTY_LAWYER:
        return "IP Lawyer";
      case AdvocateSpeciality.TAX_LAWYER:
        return "Tax Lawyer";
      case AdvocateSpeciality.LABOR_LAWYER:
        return "Labor Lawyer";
      case AdvocateSpeciality.TRADE_LAWYER:
        return "Trade Lawyer";
      case AdvocateSpeciality.BANKING_LAWYER:
        return "Banking Lawyer";
      case AdvocateSpeciality.INSURANCE_LAWYER:
        return "Insurance Lawyer";
      case AdvocateSpeciality.WOMEN_AND_CHILD_RIGHTS_LAWYER:
        return "Women & Child Rights";
    }
  }

  IconData get icon {
    switch (this) {
      case AdvocateSpeciality.CRIMINAL_LAWYER:
        return Icons.gavel;
      case AdvocateSpeciality.FAMILY_LAWYER:
        return Icons.family_restroom;
      case AdvocateSpeciality.CORPORATE_LAWYER:
        return Icons.business;
      case AdvocateSpeciality.CYBER_CRIME_LAWYER:
        return Icons.security;
      case AdvocateSpeciality.PROPERTY_LAWYER:
        return Icons.home_work;
      default:
        return Icons.balance;
    }
  }
}
