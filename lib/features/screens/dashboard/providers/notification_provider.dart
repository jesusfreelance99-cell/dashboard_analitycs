import 'package:flutter/material.dart';
import '../../../../core/models/user_model.dart';
import '../../../../core/services/user_sync_service.dart';

class NotificationProvider extends ChangeNotifier {
  final _userSyncService = UserSyncService();

  // Estado
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  List<String> _selectedUserIds = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _sendToAll = false;
  String? _errorMessage;
  String _notificationTitle = '';
  String _notificationMessage = '';

  // Getters
  List<UserModel> get allUsers => _allUsers;
  List<UserModel> get filteredUsers => _filteredUsers;
  List<String> get selectedUserIds => _selectedUserIds;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  bool get sendToAll => _sendToAll;
  String? get errorMessage => _errorMessage;
  String get notificationTitle => _notificationTitle;
  String get notificationMessage => _notificationMessage;
  int get recipientCount => _sendToAll ? _allUsers.length : _selectedUserIds.length;

  /// Inicializar - cargar usuarios desde base de datos local
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _allUsers = await _userSyncService.getAllUsersLocal();
      _filteredUsers = _allUsers;
      _errorMessage = null;
      print('✅ Usuarios cargados: ${_allUsers.length}');
    } catch (e) {
      _errorMessage = 'Error al cargar usuarios: $e';
      print('❌ Error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Buscar usuarios por nombre o email
  Future<void> searchUsers(String query) async {
    _searchQuery = query;

    if (query.isEmpty) {
      _filteredUsers = _allUsers;
    } else {
      _isLoading = true;
      notifyListeners();

      try {
        _filteredUsers = await _userSyncService.searchUsersLocal(query);
      } catch (e) {
        _errorMessage = 'Error en búsqueda: $e';
      } finally {
        _isLoading = false;
      }
    }

    notifyListeners();
  }

  /// Seleccionar/deseleccionar usuario
  void toggleUserSelection(String userId) {
    if (_selectedUserIds.contains(userId)) {
      _selectedUserIds.remove(userId);
    } else {
      _selectedUserIds.add(userId);
    }
    notifyListeners();
  }

  /// Seleccionar todos los usuarios
  void selectAllUsers() {
    _selectedUserIds = _allUsers.map((u) => u.id).toList();
    notifyListeners();
  }

  /// Deseleccionar todos
  void deselectAllUsers() {
    _selectedUserIds.clear();
    notifyListeners();
  }

  /// Toggle "Enviar a todos"
  void toggleSendToAll(bool value) {
    _sendToAll = value;
    if (_sendToAll) {
      _selectedUserIds.clear();
    }
    notifyListeners();
  }

  /// Actualizar título de notificación
  void setNotificationTitle(String title) {
    _notificationTitle = title;
    notifyListeners();
  }

  /// Actualizar mensaje de notificación
  void setNotificationMessage(String message) {
    _notificationMessage = message;
    notifyListeners();
  }

  /// Validar que la notificación sea válida
  bool isNotificationValid() {
    return _notificationTitle.isNotEmpty &&
        _notificationMessage.isNotEmpty &&
        (_sendToAll || _selectedUserIds.isNotEmpty);
  }

  /// Obtener lista de usuarios seleccionados
  List<UserModel> getSelectedUsers() {
    if (_sendToAll) {
      return _allUsers;
    }
    return _allUsers
        .where((user) => _selectedUserIds.contains(user.id))
        .toList();
  }

  /// Obtener FCM tokens de los usuarios
  Future<List<String>> getFcmTokens() async {
    try {
      if (_sendToAll) {
        return await _userSyncService.getActiveFcmTokens();
      } else {
        final tokens = <String>[];
        for (final userId in _selectedUserIds) {
          final token = await _userSyncService.getUserFcmToken(userId);
          if (token != null && token.isNotEmpty) {
            tokens.add(token);
          }
        }
        return tokens;
      }
    } catch (e) {
      _errorMessage = 'Error obteniendo tokens: $e';
      notifyListeners();
      return [];
    }
  }

  /// Limpiar formulario
  void clearForm() {
    _notificationTitle = '';
    _notificationMessage = '';
    _selectedUserIds.clear();
    _sendToAll = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Sincronizar usuarios desde Firebase (refrescar)
  Future<void> refreshUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _userSyncService.syncAllUsers();
      _allUsers = await _userSyncService.getAllUsersLocal();
      _filteredUsers = _allUsers;
      _errorMessage = null;
      print('✅ Usuarios actualizados: ${_allUsers.length}');
    } catch (e) {
      _errorMessage = 'Error actualizando usuarios: $e';
      print('❌ Error: $_errorMessage');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
