import 'package:flutter/widgets.dart';

import 'static_content_translations.dart';

class AppLocalizations {
  final Locale locale;
  const AppLocalizations(this.locale);
  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  static const supportedLocales = [
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('tr'),
  ];
  static const delegate = _Delegate();

  static const _values = <String, Map<String, String>>{
    'de': {
      'Start': 'Start',
      'Requests': 'Anfragen',
      'Help': 'Helfen',
      'Messages': 'Nachrichten',
      'Profile': 'Profil',
      'Language': 'Sprache',
      'English': 'Englisch',
      'German': 'Deutsch',
      'Spanish': 'Spanisch',
      'French': 'Französisch',
      'Turkish': 'Türkisch',
      'Availability': 'Verfügbarkeit',
      'Available now': 'Jetzt verfügbar',
      'Do not disturb': 'Nicht stören',
      'Not available today': 'Heute nicht verfügbar',
      'Equipment': 'Ausrüstung',
      'Competencies': 'Kompetenzen',
      'Dark mode': 'Dunkler Modus',
      'Sign in': 'Anmelden',
      'Create account': 'Konto erstellen',
      'Subcategory': 'Unterkategorie',
      'Urgency': 'Dringlichkeit',
      'Quick call for help': 'Schneller Hilferuf',
      'Local support': 'Lokale Unterstützung',
      'Lost & found': 'Vermisst & gefunden',
      'Immediately': 'Sofort',
      'Within hours': 'Innerhalb von Stunden',
      'Today': 'Heute',
      'Within days': 'Innerhalb von Tagen',
      'Flexible': 'Flexibel',
      'Created': 'Erstellt',
      'Searching': 'Suche läuft',
      'On the way': 'Unterwegs',
      'Arrived': 'Angekommen',
      'Completed': 'Abgeschlossen',
      'Auto closed': 'Automatisch beendet',
      'Accepted': 'Angenommen',
      'Rejected': 'Abgelehnt',
      'Pending': 'Ausstehend',
      'Available': 'Verfügbar',
      'Unavailable': 'Nicht verfügbar',
      'Urgent calls': 'Dringende Hilferufe',
      'Local help': 'Lokale Hilfe',
      'Community': 'Gemeinschaft',
      'Home location': 'Zuhause',
      'Work': 'Arbeit',
      'Association': 'Verein',
      'Other place': 'Anderer Ort',
      'First aid': 'Erste Hilfe',
      'Technically experienced': 'Technisch erfahren',
      'Electrician': 'Elektriker',
      'Bicycle repair': 'Fahrradreparatur',
      'Car assistance': 'Autohilfe',
      'Physically strong': 'Körperlich kräftig',
      'New': 'Neu',
      'Good': 'Gut',
      'Fair': 'Akzeptabel',
      'Needs maintenance': 'Wartung erforderlich',
      'General': 'Allgemein',
      'User': 'Benutzer',
      'Administrator': 'Administrator',
      'Lost': 'Verloren',
      'Found': 'Gefunden',
    },
    'es': {
      'Start': 'Inicio',
      'Requests': 'Solicitudes',
      'Help': 'Ayuda',
      'Messages': 'Mensajes',
      'Profile': 'Perfil',
      'Language': 'Idioma',
      'English': 'Inglés',
      'German': 'Alemán',
      'Spanish': 'Español',
      'French': 'Francés',
      'Turkish': 'Turco',
      'Availability': 'Disponibilidad',
      'Available now': 'Disponible ahora',
      'Do not disturb': 'No molestar',
      'Not available today': 'No disponible hoy',
      'Equipment': 'Equipo',
      'Competencies': 'Competencias',
      'Dark mode': 'Modo oscuro',
      'Sign in': 'Iniciar sesión',
      'Create account': 'Crear cuenta',
      'Subcategory': 'Subcategoría',
      'Urgency': 'Urgencia',
      'Quick call for help': 'Ayuda rápida',
      'Local support': 'Apoyo local',
      'Lost & found': 'Perdido y encontrado',
      'Immediately': 'Inmediatamente',
      'Within hours': 'En unas horas',
      'Today': 'Hoy',
      'Within days': 'En unos días',
      'Flexible': 'Flexible',
      'Created': 'Creada',
      'Searching': 'Buscando',
      'On the way': 'En camino',
      'Arrived': 'Llegó',
      'Completed': 'Completada',
      'Auto closed': 'Cerrada automáticamente',
      'Accepted': 'Aceptada',
      'Rejected': 'Rechazada',
      'Pending': 'Pendiente',
      'Available': 'Disponible',
      'Unavailable': 'No disponible',
      'Urgent calls': 'Solicitudes urgentes',
      'Local help': 'Ayuda local',
      'Community': 'Comunidad',
      'Home location': 'Casa',
      'Work': 'Trabajo',
      'Association': 'Asociación',
      'Other place': 'Otro lugar',
      'First aid': 'Primeros auxilios',
      'Technically experienced': 'Experiencia técnica',
      'Electrician': 'Electricista',
      'Bicycle repair': 'Reparación de bicicletas',
      'Car assistance': 'Asistencia de automóvil',
      'Physically strong': 'Fuerza física',
      'New': 'Nuevo',
      'Good': 'Bueno',
      'Fair': 'Aceptable',
      'Needs maintenance': 'Necesita mantenimiento',
      'General': 'General',
      'User': 'Usuario',
      'Administrator': 'Administrador',
      'Lost': 'Perdido',
      'Found': 'Encontrado',
    },
    'fr': {
      'Start': 'Accueil',
      'Requests': 'Demandes',
      'Help': 'Aide',
      'Messages': 'Messages',
      'Profile': 'Profil',
      'Language': 'Langue',
      'English': 'Anglais',
      'German': 'Allemand',
      'Spanish': 'Espagnol',
      'French': 'Français',
      'Turkish': 'Turc',
      'Availability': 'Disponibilité',
      'Available now': 'Disponible maintenant',
      'Do not disturb': 'Ne pas déranger',
      'Not available today': 'Indisponible aujourd’hui',
      'Equipment': 'Équipement',
      'Competencies': 'Compétences',
      'Dark mode': 'Mode sombre',
      'Sign in': 'Se connecter',
      'Create account': 'Créer un compte',
      'Subcategory': 'Sous-catégorie',
      'Urgency': 'Urgence',
      'Quick call for help': 'Appel à l’aide rapide',
      'Local support': 'Aide locale',
      'Lost & found': 'Perdu et trouvé',
      'Immediately': 'Immédiatement',
      'Within hours': 'Dans quelques heures',
      'Today': 'Aujourd’hui',
      'Within days': 'Dans quelques jours',
      'Flexible': 'Flexible',
      'Created': 'Créée',
      'Searching': 'Recherche',
      'On the way': 'En route',
      'Arrived': 'Arrivé',
      'Completed': 'Terminée',
      'Auto closed': 'Fermée automatiquement',
      'Accepted': 'Acceptée',
      'Rejected': 'Refusée',
      'Pending': 'En attente',
      'Available': 'Disponible',
      'Unavailable': 'Indisponible',
      'Urgent calls': 'Appels urgents',
      'Local help': 'Aide locale',
      'Community': 'Communauté',
      'Home location': 'Domicile',
      'Work': 'Travail',
      'Association': 'Association',
      'Other place': 'Autre lieu',
      'First aid': 'Premiers secours',
      'Technically experienced': 'Expérience technique',
      'Electrician': 'Électricien',
      'Bicycle repair': 'Réparation de vélos',
      'Car assistance': 'Assistance automobile',
      'Physically strong': 'Bonne condition physique',
      'New': 'Neuf',
      'Good': 'Bon',
      'Fair': 'Correct',
      'Needs maintenance': 'Entretien nécessaire',
      'General': 'Général',
      'User': 'Utilisateur',
      'Administrator': 'Administrateur',
      'Lost': 'Perdu',
      'Found': 'Trouvé',
    },
    'tr': {
      'Start': 'Ana sayfa',
      'Requests': 'Talepler',
      'Help': 'Yardım',
      'Messages': 'Mesajlar',
      'Profile': 'Profil',
      'Language': 'Dil',
      'English': 'İngilizce',
      'German': 'Almanca',
      'Spanish': 'İspanyolca',
      'French': 'Fransızca',
      'Turkish': 'Türkçe',
      'Availability': 'Müsaitlik',
      'Available now': 'Şimdi müsait',
      'Do not disturb': 'Rahatsız etmeyin',
      'Not available today': 'Bugün müsait değil',
      'Equipment': 'Ekipman',
      'Competencies': 'Yetkinlikler',
      'Dark mode': 'Koyu mod',
      'Sign in': 'Giriş yap',
      'Create account': 'Hesap oluştur',
      'Subcategory': 'Alt kategori',
      'Urgency': 'Aciliyet',
      'Quick call for help': 'Hızlı yardım çağrısı',
      'Local support': 'Yerel destek',
      'Lost & found': 'Kayıp ve bulunan',
      'Immediately': 'Hemen',
      'Within hours': 'Saatler içinde',
      'Today': 'Bugün',
      'Within days': 'Günler içinde',
      'Flexible': 'Esnek',
      'Created': 'Oluşturuldu',
      'Searching': 'Aranıyor',
      'On the way': 'Yolda',
      'Arrived': 'Ulaştı',
      'Completed': 'Tamamlandı',
      'Auto closed': 'Otomatik kapatıldı',
      'Accepted': 'Kabul edildi',
      'Rejected': 'Reddedildi',
      'Pending': 'Bekliyor',
      'Available': 'Müsait',
      'Unavailable': 'Müsait değil',
      'Urgent calls': 'Acil çağrılar',
      'Local help': 'Yerel yardım',
      'Community': 'Topluluk',
      'Home location': 'Ev',
      'Work': 'İş',
      'Association': 'Dernek',
      'Other place': 'Diğer yer',
      'First aid': 'İlk yardım',
      'Technically experienced': 'Teknik deneyimli',
      'Electrician': 'Elektrikçi',
      'Bicycle repair': 'Bisiklet tamiri',
      'Car assistance': 'Araba yardımı',
      'Physically strong': 'Fiziksel olarak güçlü',
      'New': 'Yeni',
      'Good': 'İyi',
      'Fair': 'Orta',
      'Needs maintenance': 'Bakım gerekli',
      'General': 'Genel',
      'User': 'Kullanıcı',
      'Administrator': 'Yönetici',
      'Lost': 'Kayıp',
      'Found': 'Bulundu',
    },
  };
  static const _enumLabels = <String, String>{
    'immediately': 'Immediately',
    'hours': 'Within hours',
    'today': 'Today',
    'days': 'Within days',
    'flexible': 'Flexible',
    'created': 'Created',
    'searching': 'Searching',
    'helper_assigned': 'Accepted',
    'helper_on_way': 'On the way',
    'helper_on_site': 'Arrived',
    'completed': 'Completed',
    'auto_closed': 'Auto closed',
    'cancelled': 'Rejected',
    'accepted': 'Accepted',
    'rejected': 'Rejected',
    'notified': 'Pending',
    'on_way': 'On the way',
    'on_site': 'Arrived',
    'finished': 'Completed',
    'available': 'Available',
    'unavailable': 'Unavailable',
    'do_not_disturb': 'Do not disturb',
    'unavailable_today': 'Not available today',
    'urgent': 'Urgent calls',
    'local': 'Local help',
    'community': 'Community',
    'home': 'Home location',
    'work': 'Work',
    'association': 'Association',
    'custom': 'Other place',
    'other': 'Other place',
    'quick_help': 'Quick call for help',
    'local_support': 'Local support',
    'lost_found': 'Lost & found',
    'new': 'New',
    'good': 'Good',
    'fair': 'Fair',
    'needs_maintenance': 'Needs maintenance',
    'help': 'Help',
    'general': 'General',
    'user': 'User',
    'admin': 'Administrator',
    'lost': 'Lost',
    'found': 'Found',
  };
  static Iterable<String> get supportedStaticOptionKeys => _enumLabels.keys;
  static Set<String> get supportedStaticContentKeys => {
    ...staticContentTranslations['de']!.keys,
    ...additionalStaticContentTranslations['de']!.keys,
    ...remainingStaticContentTranslations['de']!.keys,
    ...formFieldTranslations['de']!.keys,
    ...systemFeedbackTranslations['de']!.keys,
    ...dynamicFeedbackTranslations['de']!.keys,
  };
  bool hasStaticContentTranslation(String key) =>
      locale.languageCode == 'en' ||
      staticContentTranslations[locale.languageCode]?.containsKey(key) ==
          true ||
      additionalStaticContentTranslations[locale.languageCode]?.containsKey(
            key,
          ) ==
          true ||
      remainingStaticContentTranslations[locale.languageCode]?.containsKey(
            key,
          ) ==
          true ||
      formFieldTranslations[locale.languageCode]?.containsKey(key) == true ||
      systemFeedbackTranslations[locale.languageCode]?.containsKey(key) ==
          true ||
      dynamicFeedbackTranslations[locale.languageCode]?.containsKey(key) ==
          true;
  String t(String value) =>
      _values[locale.languageCode]?[value] ??
      staticContentTranslations[locale.languageCode]?[value] ??
      additionalStaticContentTranslations[locale.languageCode]?[value] ??
      remainingStaticContentTranslations[locale.languageCode]?[value] ??
      formFieldTranslations[locale.languageCode]?[value] ??
      systemFeedbackTranslations[locale.languageCode]?[value] ??
      dynamicFeedbackTranslations[locale.languageCode]?[value] ??
      _dynamic(value) ??
      value;

  String? _dynamic(String value) {
    if (value.startsWith('Exception: ')) {
      return t(value.substring('Exception: '.length));
    }
    final ready = RegExp(r'^Nearby alerts ready · (\d+) devices?$')
        .firstMatch(value);
    if (ready != null) {
      final count = int.parse(ready.group(1)!);
      return '${t('Nearby alerts ready')} · $count ${t(count == 1 ? 'device' : 'devices')}';
    }
    for (final prefix in ['Setup needed', 'Notifications need attention']) {
      if (value.startsWith('$prefix:')) {
        return '${t(prefix)}:${value.substring(prefix.length + 1)}';
      }
    }
    final patterns = <RegExp, String>{
      RegExp(r'^Location: (.+)$'): 'Location',
      RegExp(r'^Equipment: (.+)$'): 'Equipment',
      RegExp(r'^Contact: (.+)$'): 'Contact preference',
      RegExp(r'^Category: (.+)$'): 'Category',
      RegExp(r'^Help type: (.+)$'): 'Help type',
      RegExp(r'^When: (.+)$'): 'When',
      RegExp(r'^Equipment requested: (.+)$'): 'Equipment requested',
    };
    for (final entry in patterns.entries) {
      final match = entry.key.firstMatch(value);
      if (match != null) return '${t(entry.value)}: ${match.group(1)}';
    }
    final minutes = RegExp(r'^(\d+) minutes$').firstMatch(value);
    if (minutes != null) return '${minutes.group(1)} ${t('minutes')}';
    final items = RegExp(r'^(\d+) items available$').firstMatch(value);
    if (items != null) return '${items.group(1)} ${t('items available')}';
    final subs = RegExp(r'^(\d+) subcategories$').firstMatch(value);
    if (subs != null) return '${subs.group(1)} ${t('subcategories')}';
    final capabilities = RegExp(r'^User Capabilities · (.+)$')
        .firstMatch(value);
    if (capabilities != null) {
      return '${t('User Capabilities')} · ${capabilities.group(1)}';
    }
    final equipment = RegExp(r'^(\d+) items? needed$').firstMatch(value);
    if (equipment != null) {
      final count = int.parse(equipment.group(1)!);
      return '$count ${t(count == 1 ? 'item needed' : 'items needed')}';
    }
    final notified = RegExp(r'^(\d+) nearby devices? notified successfully\.$')
        .firstMatch(value);
    if (notified != null) {
      final count = int.parse(notified.group(1)!);
      final template = t(
        count == 1
            ? '{count} nearby device notified successfully.'
            : '{count} nearby devices notified successfully.',
      );
      return template.replaceFirst('{count}', '$count');
    }
    final matched = RegExp(
      r'^(\d+) nearby helpers? matched, but none had a registered notification device\. They can still see it after refreshing their helper inbox\.$',
    ).firstMatch(value);
    if (matched != null) {
      final count = int.parse(matched.group(1)!);
      final template = t(
        count == 1
            ? '{count} nearby helper matched, but none had a registered notification device. They can still see it after refreshing their helper inbox.'
            : '{count} nearby helpers matched, but none had a registered notification device. They can still see it after refreshing their helper inbox.',
      );
      return template.replaceFirst('{count}', '$count');
    }
    final testNotification = RegExp(
      r'^Test notification sent to (\d+) devices?\.$',
    ).firstMatch(value);
    if (testNotification != null) {
      final count = int.parse(testNotification.group(1)!);
      final template = t(
        count == 1
            ? 'Test notification sent to {count} device.'
            : 'Test notification sent to {count} devices.',
      );
      return template.replaceFirst('{count}', '$count');
    }
    final testFailure = RegExp(r'^Test delivery failed(?:: (.+))?\.$')
        .firstMatch(value);
    if (testFailure != null) {
      final details = testFailure.group(1);
      return details == null
          ? '${t('Test delivery failed')}.'
          : '${t('Test delivery failed')}: $details';
    }
    return null;
  }

  String enumValue(dynamic value) {
    final key = value?.toString() ?? '';
    return t(_enumLabels[key] ?? key);
  }
}

class _Delegate extends LocalizationsDelegate<AppLocalizations> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (item) => item.languageCode == locale.languageCode,
  );
  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);
  @override
  bool shouldReload(_Delegate old) => false;
}

extension TranslateContext on BuildContext {
  String tr(String value) => AppLocalizations.of(this).t(value);
  String enumLabel(dynamic value) => AppLocalizations.of(this).enumValue(value);
}
