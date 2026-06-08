import 'package:flutter/material.dart';

enum DashPage { overview, funnel, cac, features, retention, users, notifications }

enum DateRange { d7, d30, d90, all }

class DashboardProvider extends ChangeNotifier {
  // Sidebar
  bool _collapsed = false;
  bool get collapsed => _collapsed;

  void toggleCollapse() {
    _collapsed = !_collapsed;
    notifyListeners();
  }

  // Navigation
  DashPage _page = DashPage.overview;
  DashPage get page => _page;

  void setPage(DashPage p) {
    _page = p;
    notifyListeners();
  }

  // Date range
  DateRange _range = DateRange.d30;
  DateRange get range => _range;

  void setRange(DateRange r) {
    _range = r;
    notifyListeners();
  }

  // Data per range
  static const _data = {
    DateRange.d7:  RangeData(imp:'3,100',  dl:'61',  cvr:'1.9%', mrr:r'$142', rev:r'$48',  subs:'3',  trials:'8',  churn:'0%',  users:'6',  col:'56'),
    DateRange.d30: RangeData(imp:'12,400', dl:'284', cvr:'2.3%', mrr:r'$142', rev:r'$198', subs:'11', trials:'23', churn:'9%',  users:'40', col:'261'),
    DateRange.d90: RangeData(imp:'28,000', dl:'610', cvr:'2.2%', mrr:r'$142', rev:r'$420', subs:'11', trials:'31', churn:'12%', users:'40', col:'560'),
    DateRange.all: RangeData(imp:'28,000', dl:'610', cvr:'2.2%', mrr:r'$142', rev:r'$420', subs:'11', trials:'31', churn:'12%', users:'40', col:'560'),
  };

  RangeData get currentData => _data[_range]!;

  String get rangeLabel {
    switch (_range) {
      case DateRange.d7:  return 'últimos 7 días';
      case DateRange.d30: return 'últimos 30 días';
      case DateRange.d90: return 'últimos 90 días';
      case DateRange.all: return 'todo el tiempo';
    }
  }

  static DateTime? rangeStart(DateRange range) {
    final now = DateTime.now();
    switch (range) {
      case DateRange.d7:  return now.subtract(const Duration(days: 7));
      case DateRange.d30: return now.subtract(const Duration(days: 30));
      case DateRange.d90: return now.subtract(const Duration(days: 90));
      case DateRange.all: return null;
    }
  }
}

class RangeData {
  final String imp, dl, cvr, mrr, rev, subs, trials, churn, users, col;
  const RangeData({
    required this.imp, required this.dl, required this.cvr,
    required this.mrr, required this.rev, required this.subs,
    required this.trials, required this.churn, required this.users,
    required this.col,
  });
}
