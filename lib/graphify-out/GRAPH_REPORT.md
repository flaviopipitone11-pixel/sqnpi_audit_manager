# Graph Report - lib  (2026-07-09)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 2684 nodes · 3890 edges · 83 communities (79 shown, 4 thin omitted)
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1ef28446`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- app_database.dart
- visit_workspace_page.dart
- attachments_page.dart
- report_template.dart
- checklist_page.dart
- home_page.dart
- post_raccolta_section.dart
- admin_dashboard_page.dart
- DataClass
- personal_notes_page.dart
- ConsumerWidget
- authControllerProvider
- StatelessWidget
- admin_companies_page.dart
- create_visit_page.dart
- alerts_provider.dart
- audits_repository.dart
- nc_page.dart
- visits_map_view.dart
- ConsumerState
- report_service.dart
- admin_inspectors_page.dart
- ../../../core/storage/db_providers.dart
- appDatabaseProvider
- admin_create_visit_page.dart
- login_page.dart
- State
- admin_calendar_page.dart
- map_cache_provider.dart
- Table
- audit_stats_provider.dart
- final_evaluation_page.dart
- build
- sync_controller.dart
- signup_page.dart
- admin_chat_page.dart
- visits_page.dart
- chat_page.dart
- pulse_marker.dart
- router.dart
- build
- seasonal_asset_manager.dart
- auth_controller.dart
- signature_dialog.dart
- build
- radio_group.dart
- chat_repository.dart
- report_provider.dart
- _VisitWorkspacePageState
- admin_shell.dart
- package:flutter_riverpod/flutter_riverpod.dart
- admin_map_page.dart
- settings_page.dart
- visit_outcome.dart
- ../../../core/storage/app_database.dart
- HomeShell
- admin_repository.dart
- admin_checklist_page.dart
- dashboard_stats.dart
- inspector_action_service.dart
- ../../auth/presentation/auth_controller.dart
- DateTime
- app.dart
- report_page.dart
- package:flutter/material.dart
- sanctions_provider.dart
- auth_state.dart
- sync_log_dialog.dart
- mass_balance_provider.dart
- home_shell.dart
- inspector_workload.dart
- Color
- _AttachmentsPageState
- _ChatPageState
- _VisitsPageState
- List
- help_texts.dart
- CustomPainter
- _AttachmentBadge
- ReportTemplate
- _AnnotationEditor
- _GalleryView
- build

## God Nodes (most connected - your core abstractions)
1. `appDatabaseProvider` - 82 edges
2. `authControllerProvider` - 43 edges
3. `DataClass` - 21 edges
4. `activityLoggerProvider` - 21 edges
5. `build` - 18 edges
6. `adminRepositoryProvider` - 15 edges
7. `auditsRepositoryProvider` - 14 edges
8. `AppDatabase` - 12 edges
9. `visitsWithCompanyProvider` - 11 edges
10. `companyByVisitIdProvider` - 11 edges

## Surprising Connections (you probably didn't know these)
- `_saveField` --references--> `appDatabaseProvider`  [EXTRACTED]
  features/audits/presentation/nc_page.dart → core/storage/db_providers.dart
- `AuthListenable` --references--> `authControllerProvider`  [EXTRACTED]
  app/router.dart → features/auth/presentation/auth_controller.dart
- `_geocodeAddress` --references--> `geocodingServiceProvider`  [EXTRACTED]
  features/admin/presentation/admin_create_visit_page.dart → core/services/geocoding_service.dart
- `_geocodeOperationalAddress` --references--> `geocodingServiceProvider`  [EXTRACTED]
  features/audits/presentation/create_visit_page.dart → core/services/geocoding_service.dart
- `_AdminCalendarPageState` --references--> `appDatabaseProvider`  [EXTRACTED]
  features/admin/presentation/admin_calendar_page.dart → core/storage/db_providers.dart

## Import Cycles
- None detected.

## Communities (83 total, 4 thin omitted)

### Community 0 - "app_database.dart"
Cohesion: 0.00
Nodes (738): BoolColumn get, class BroadcastMessage extends, class ChecklistResponse extends, class ChecklistVersion extends, class MassBalanceDocument extends, class MassBalanceRecord extends, class PostHarvestRecord extends, class VisitPreviousNcManagement extends (+730 more)

### Community 1 - "visit_workspace_page.dart"
Cohesion: 0.01
Nodes (168): ../application/management_sync_service.dart, ../application/visit_validation_provider.dart, attachments_page.dart, checklist_page.dart, Color? iconColor,
  String, _addSignature, _allControllers, _animation (+160 more)

### Community 2 - "attachments_page.dart"
Cohesion: 0.02
Nodes (81): ../../../core/utils/image_utils.dart, attachment, AttachmentFilter, attachments, _buildCategoryGroup, _buildExtraField, _buildHeader, _buildSearchAndFilters (+73 more)

### Community 3 - "report_template.dart"
Cohesion: 0.03
Nodes (78): accentColor, _buildActivitiesSummaryCompliance, _buildBulletItem, buildCheck, _buildCheckItem, buildChecklistPage, _buildColumnValue, buildCompanyInfoPage (+70 more)

### Community 4 - "checklist_page.dart"
Cohesion: 0.03
Nodes (74): ../../admin/application/activity_logger.dart, BorderRadius, BoxFit, ../../../core/domain/visit_outcome.dart, Conformita, double?, allResponsesByUecProvider, _areUecsEqual (+66 more)

### Community 5 - "home_page.dart"
Cohesion: 0.03
Nodes (60): ../application/audit_stats_provider.dart, ../application/weather_provider.dart, ../../../core/sync/sync_controller.dart, ../../../core/utils/seasonal_asset_manager.dart, dart:math, animationValue, _buildFilteredVisits, _buildSectionHeader (+52 more)

### Community 6 - "post_raccolta_section.dart"
Cohesion: 0.03
Nodes (60): bool?, _addMassBalance, build, _buildMassBalance, _buildPostHarvestGrid, _buildTraceability, certificatoTerzista, child (+52 more)

### Community 7 - "admin_dashboard_page.dart"
Cohesion: 0.04
Nodes (59): ../application/admin_export_service.dart, ../application/alerts_provider.dart, checklist_manager_page.dart, adminExportServiceProvider, adminAlertsProvider, AdminDashboardPage, _AdminDashboardPageState, adminSearchQueryProvider (+51 more)

### Community 8 - "DataClass"
Cohesion: 0.08
Nodes (47): ChecklistItemExtension, company, visit, VisitWithCompany, Insertable, UpdateCompanion, ActivityLog, ActivityLogsCompanion (+39 more)

### Community 9 - "personal_notes_page.dart"
Cohesion: 0.05
Nodes (42): ../application/personal_notes_provider.dart, addNote, content, copyWith, createdAt, deleteNote, fromJson, _getFile (+34 more)

### Community 10 - "ConsumerWidget"
Cohesion: 0.08
Nodes (39): ../application/logs_export_service.dart, ConsumerWidget, logsExportServiceProvider, AdminLogsPage, _AdminLogsPageState, build, _buildActionIcon, _buildDateSeparator (+31 more)

### Community 11 - "authControllerProvider"
Cohesion: 0.07
Nodes (41): geocodingServiceProvider, activityLoggerProvider, adminRepositoryProvider, _showEditItemDialog, AdminCompaniesPage, _AdminCompaniesPageState, _importCompaniesFromExcel, _showAdvancedDeleteDialog (+33 more)

### Community 12 - "StatelessWidget"
Cohesion: 0.05
Nodes (40): _ConfigurationTools, _ExportButton, _MiniStat, _SeverityItem, _StatCard, _ToolCard, _VisitCard, _ActionButton (+32 more)

### Community 13 - "admin_companies_page.dart"
Cohesion: 0.06
Nodes (37): _addressController, build, _buildLegendRow, _buildModernTextField, _buildStatusChip, _capController, _cityController, company (+29 more)

### Community 14 - "create_visit_page.dart"
Cohesion: 0.06
Nodes (35): ../../admin/data/admin_repository.dart, DateTimeRange, _btnCircle, build, _buildCard, _buildField, _buildSectionHeader, _companyController (+27 more)

### Community 15 - "alerts_provider.dart"
Cohesion: 0.06
Nodes (34): app_database.dart, companyProvider, db, fasiProvider, responsesProvider, uecsProvider, visitProvider, watchClosingByVisitId (+26 more)

### Community 16 - "audits_repository.dart"
Cohesion: 0.07
Nodes (32): @DriftDatabase, AppDatabase, dart:convert, ActivityLogger, db, log, db, logger (+24 more)

### Community 17 - "nc_page.dart"
Cohesion: 0.06
Nodes (34): ../application/checklist_item_helpers.dart, class, AdministrativeSection, build, child, closing, createState, _cropsController (+26 more)

### Community 18 - "visits_map_view.dart"
Cohesion: 0.06
Nodes (33): ../../../../core/storage/map_cache_provider.dart, mapCacheStoreProvider, ../domain/visit_with_company.dart, code, condition, current, dio, _getIconForCode (+25 more)

### Community 19 - "ConsumerState"
Cohesion: 0.08
Nodes (35): ConsumerState, ConsumerStatefulWidget, inspectorsWorkloadProvider, AdminImportPage, _AdminImportPageState, AdminInspectorsPage, _AdminInspectorsPageState, _SpecialDocumentationSection (+27 more)

### Community 20 - "report_service.dart"
Cohesion: 0.06
Nodes (30): ../../../core/utils/file_storage_utils.dart, dart:isolate, end, _buildChecklistPdfBytes, _buildPdfBytes, _buildPhotoGalleryPdfBytes, _cachedLogoBios, _cachedLogoSqnpi (+22 more)

### Community 21 - "admin_inspectors_page.dart"
Cohesion: 0.07
Nodes (30): ../data/workload_providers.dart, _AccountBadge, build, _buildModernTextField, color, _ContactInfo, count, createState (+22 more)

### Community 22 - "../../../core/storage/db_providers.dart"
Cohesion: 0.08
Nodes (26): ../../audits/domain/visit_with_company.dart, ../../../core/storage/db_providers.dart, ../domain/inspector_workload.dart, AdminExportService, db, exportSummaryPdf, exportToExcel, _getStatusLabel (+18 more)

### Community 23 - "appDatabaseProvider"
Cohesion: 0.06
Nodes (39): appDatabaseProvider, build, _buildRecipientSection, _bulkDelete, _bulkLink, _confirmDelete, _handleDeleteSpecial, _handlePaths (+31 more)

### Community 24 - "admin_create_visit_page.dart"
Cohesion: 0.07
Nodes (26): ../../../core/services/geocoding_service.dart, _addressController, _buildDatePicker, _buildInspectorDropdown, _buildModernTextField, _buildSectionCard, _cityController, _companyController (+18 more)

### Community 25 - "login_page.dart"
Cohesion: 0.09
Nodes (22): _animCtrl, _buildRoleButton, _contentFade, _contentSlide, createState, dispose, _doLogin, _error (+14 more)

### Community 26 - "State"
Cohesion: 0.13
Nodes (22): _PersistentImage, _PersistentImageState, _PersistentImage, _PersistentImageState, _ActionCard, _ActionCardState, _AnimatedSyncIcon, _AnimatedSyncIconState (+14 more)

### Community 27 - "admin_calendar_page.dart"
Cohesion: 0.10
Nodes (20): admin_create_visit_page.dart, CalendarFormat, _ActionIcon, AdminCalendarPage, _AdminCalendarPageState, _buildMiniSummary, _calendarFormat, color (+12 more)

### Community 28 - "map_cache_provider.dart"
Cohesion: 0.11
Nodes (18): CacheOptions, CacheStore, cacheDir, cachePath, dir, mapCacheOptionsProvider, store, FileStorageUtils (+10 more)

### Community 29 - "Table"
Cohesion: 0.10
Nodes (21): ActivityLogs, BroadcastMessages, ChecklistItems, ChecklistResponses, ChecklistVersions, VisitPreviousNcManagements, Inspectors, MassBalanceDocuments (+13 more)

### Community 30 - "audit_stats_provider.dart"
Cohesion: 0.10
Nodes (20): double get, AlertType, auth, averageNcPoints, closedVisits, completedCount, db, description (+12 more)

### Community 31 - "final_evaluation_page.dart"
Cohesion: 0.12
Nodes (19): ../../../core/constants/help_texts.dart, closingProvider, ../../../core/widgets/help_tooltip.dart, ../../../core/widgets/radio_group.dart, build, _buildStyledRadioOption, createState, _debouncedSave (+11 more)

### Community 32 - "build"
Cohesion: 0.14
Nodes (17): attachmentsProvider, auditProgressProvider, validationAlertsProvider, visitValidationProvider, _AttachmentBadge, _attachmentCountProvider, _AttachmentUploader, build (+9 more)

### Community 33 - "sync_controller.dart"
Cohesion: 0.11
Nodes (19): _checkPendingItems, _connectivitySub, copyWith, _db, dispose, hashCode, _init, lastSync (+11 more)

### Community 34 - "signup_page.dart"
Cohesion: 0.11
Nodes (19): build, _buildInputDecoration, createState, dispose, _emailController, _firstNameController, _formKey, _handleSignup (+11 more)

### Community 35 - "admin_chat_page.dart"
Cohesion: 0.11
Nodes (19): AdminChatPage, _AdminChatPageState, _buildInput, _ChatBubble, createState, dispose, _focusNode, initState (+11 more)

### Community 36 - "visits_page.dart"
Cohesion: 0.11
Nodes (17): AsyncValue, ../../../core/widgets/sync_log_dialog.dart, auth, _buildStats, color, createState, db, _getStatusIcon (+9 more)

### Community 37 - "chat_page.dart"
Cohesion: 0.11
Nodes (17): _buildInput, _ChatBubble, createState, date, _DateHeader, dispose, _focusNode, initState (+9 more)

### Community 38 - "pulse_marker.dart"
Cohesion: 0.12
Nodes (16): Animation, AnimationController, build, color, _controller, createState, dispose, icon (+8 more)

### Community 39 - "router.dart"
Cohesion: 0.12
Nodes (16): AuthListenable, dispose, _subscription, ChangeNotifier, ../features/admin/presentation/admin_shell.dart, ../features/audits/presentation/create_visit_page.dart, ../features/audits/presentation/home_shell.dart, ../features/audits/presentation/visit_workspace_page.dart (+8 more)

### Community 40 - "build"
Cohesion: 0.14
Nodes (17): visitOutcomeSummaryProvider, fasiProvider, build, checklistFocusProvider, _ChecklistItemCard, _ChecklistItemCardState, checklistItemsByFaseProvider, _ChecklistList (+9 more)

### Community 41 - "seasonal_asset_manager.dart"
Cohesion: 0.12
Nodes (16): assetPath, _calculateEaster, endColor, getAssetConfig, _getHoliday, _getHolidayConfig, _getSeason, _getSeasonConfig (+8 more)

### Community 42 - "auth_controller.dart"
Cohesion: 0.12
Nodes (16): ../domain/auth_state.dart, changePassword, _init, _kPassword, _kRemember, _kUsername, login, logout (+8 more)

### Community 43 - "signature_dialog.dart"
Cohesion: 0.13
Nodes (15): build, _controller, createState, dispose, _handleSave, initialSignerName, initState, _nameController (+7 more)

### Community 44 - "build"
Cohesion: 0.14
Nodes (15): syncStatusProvider, globalStatsProvider, lastSyncStatusProvider, weatherProvider, _BroadcastAlertsSection, build, _buildAppBar, _buildTimeline (+7 more)

### Community 45 - "radio_group.dart"
Cohesion: 0.16
Nodes (14): build, child, CustomRadioGroup, _CustomRadioGroupScope, CustomRadioOption, groupValue, label, onChanged (+6 more)

### Community 46 - "chat_repository.dart"
Cohesion: 0.13
Nodes (14): dart:async, ../domain/chat_message.dart, ChatRepository, deleteChat, joinAsAdmin, leavePresence, _presenceChannel, repo (+6 more)

### Community 47 - "report_provider.dart"
Cohesion: 0.17
Nodes (14): checklistPdfProvider, db, photoGalleryPdfProvider, reportPdfProvider, reportServiceProvider, service, watchChecklistReportBytes, watchPhotoGalleryReportBytes (+6 more)

### Community 48 - "_VisitWorkspacePageState"
Cohesion: 0.29
Nodes (8): _buildBody, _buildDrawer, _buildValidationSection, visitByIdProvider, visitWorkspaceIndexProvider, VisitWorkspacePage, _VisitWorkspacePageState, Route /home

### Community 49 - "admin_shell.dart"
Cohesion: 0.16
Nodes (13): admin_calendar_page.dart, admin_companies_page.dart, admin_dashboard_page.dart, admin_inspectors_page.dart, admin_logs_page.dart, admin_map_page.dart, ../application/activity_logger.dart, ../../chat/presentation/admin_chat_list_page.dart (+5 more)

### Community 50 - "package:flutter_riverpod/flutter_riverpod.dart"
Cohesion: 0.15
Nodes (11): app/app.dart, GeocodingService, ../../../core/utils/package_info_provider.dart, log, logFile, main, package:flutter_riverpod/flutter_riverpod.dart, package:intl/date_symbol_data_local.dart (+3 more)

### Community 51 - "admin_map_page.dart"
Cohesion: 0.14
Nodes (13): ../../audits/data/audits_repository.dart, ../../audits/presentation/visit_workspace_page.dart, ../../../core/widgets/pulse_marker.dart, _buildEventList, _buildLegend, _getStatusColor, _getStatusLabel, _infoRow (+5 more)

### Community 52 - "settings_page.dart"
Cohesion: 0.15
Nodes (13): auth_controller.dart, _confirmPasswordController, createState, dispose, _error, _loading, _newPasswordController, _obscureConfirm (+5 more)

### Community 53 - "visit_outcome.dart"
Cohesion: 0.15
Nodes (12): bool get, fromRaw, isEsitoFavorevole, outcome, sogliaOperatore, sogliaUec, sumOperatoreTotale, sumUecTotale (+4 more)

### Community 54 - "../../../core/storage/app_database.dart"
Cohesion: 0.15
Nodes (11): checklist_item_helpers.dart, ../../../core/storage/app_database.dart, ChecklistItemHelpers, getIndicazioniOdc, getScoreText, getSingleScoreText, isPhaseVisible, firstMissingCode (+3 more)

### Community 55 - "HomeShell"
Cohesion: 0.22
Nodes (12): seedDatabaseProvider, packageInfoProvider, _buildKpiRow, _buildQuickActions, build, HomeShell, homeNavigationProvider, isRailExtendedProvider (+4 more)

### Community 56 - "admin_repository.dart"
Cohesion: 0.15
Nodes (12): advancedDeleteCompany, clearAllActivityLogs, db, deleteBroadcastMessage, deleteInspectorFromCloud, pushBroadcastMessageToCloud, pushCompanyToCloud, pushInspectorToCloud (+4 more)

### Community 57 - "admin_checklist_page.dart"
Cohesion: 0.19
Nodes (12): AdminChecklistPage, _AdminChecklistPageState, build, _buildField, checklistFasiProvider, createState, db, _searchController (+4 more)

### Community 58 - "dashboard_stats.dart"
Cohesion: 0.15
Nodes (12): build, _calculateStats, child, completed, DashboardStats, _DashboardStatsData, scheduled, _StatCard (+4 more)

### Community 59 - "inspector_action_service.dart"
Cohesion: 0.17
Nodes (11): activity_logger.dart, ../data/admin_repository.dart, adminRepo, createAccount, db, InspectorActionService, inspectorActionServiceProvider, logger (+3 more)

### Community 60 - "../../auth/presentation/auth_controller.dart"
Cohesion: 0.23
Nodes (11): admin_chat_page.dart, ../../auth/presentation/auth_controller.dart, ../data/chat_repository.dart, chatRepositoryProvider, AdminChatListPage, _AdminChatListPageState, build, createState (+3 more)

### Community 61 - "DateTime"
Cohesion: 0.17
Nodes (11): DateTime, ChatMessage, createdAt, fromJson, id, inspectorId, isAdmin, message (+3 more)

### Community 62 - "app.dart"
Cohesion: 0.20
Nodes (10): AppScrollBehavior, build, dragDevices, SqnpiAuditManagerApp, appRouterProvider, dart:ui, MaterialScrollBehavior, package:flutter_localizations/flutter_localizations.dart (+2 more)

### Community 63 - "report_page.dart"
Cohesion: 0.18
Nodes (10): ../application/report_provider.dart, dart:typed_data, _buildExportCard, _buildFeatureItem, _handleAction, mode, ReportPage, ReportType (+2 more)

### Community 64 - "package:flutter/material.dart"
Cohesion: 0.22
Nodes (9): ../data/audits_repository.dart, build, AdminMapPage, build, visitsWithCompanyProvider, build, MapPage, package:flutter/material.dart (+1 more)

### Community 65 - "sanctions_provider.dart"
Cohesion: 0.20
Nodes (9): db, empty, excludedUecIds, isCompanySuspended, isUecExcluded, sanctionsProvider, SanctionsStatus, totalNcPoints (+1 more)

### Community 66 - "auth_state.dart"
Cohesion: 0.20
Nodes (9): authenticated, fullName, inspectorCode, isAdmin, isAuthenticated, isFirstLogin, unauthenticated, userId (+1 more)

### Community 67 - "sync_log_dialog.dart"
Cohesion: 0.22
Nodes (8): build, _buildEmptyState, _buildFooter, _buildHeader, log, _LogItem, logs, SyncLogDialog

### Community 68 - "mass_balance_provider.dart"
Cohesion: 0.22
Nodes (8): discrepancyPercentage, empty, isOverThreshold, MassBalanceData, massBalanceProvider, purchased, stock, used

### Community 69 - "home_shell.dart"
Cohesion: 0.25
Nodes (7): ../../chat/presentation/chat_page.dart, _buildNavItem, home_page.dart, map_page.dart, navigation_providers.dart, ../../notes/presentation/personal_notes_page.dart, visits_page.dart

### Community 70 - "inspector_workload.dart"
Cohesion: 0.25
Nodes (7): completedCount, inProgressCount, inspector, InspectorWorkload, plannedCount, totalCount, int get

### Community 71 - "Color"
Cohesion: 0.29
Nodes (6): Color, build, color, HelpTooltip, size, text

### Community 72 - "_AttachmentsPageState"
Cohesion: 0.33
Nodes (6): attachmentsByVisitProvider, AttachmentsPage, _AttachmentsPageState, build, checklistCodesProvider, uecsForVisitProvider

### Community 73 - "_ChatPageState"
Cohesion: 0.40
Nodes (6): adminPresenceProvider, chatMessagesProvider, build, build, ChatPage, _ChatPageState

### Community 74 - "_VisitsPageState"
Cohesion: 0.50
Nodes (5): build, filteredVisitsProvider, visitSearchQueryProvider, VisitsPage, _VisitsPageState

### Community 75 - "List"
Cohesion: 0.40
Nodes (5): AuthState, AuthController, PersonalNotesNotifier, List, StateNotifier

### Community 76 - "help_texts.dart"
Cohesion: 0.50
Nodes (3): all, HelpTexts, static const Map

### Community 77 - "CustomPainter"
Cohesion: 0.50
Nodes (4): CustomPainter, _DashPainter, _ParticlePainter, _SparklinePainter

### Community 78 - "_AttachmentBadge"
Cohesion: 0.50
Nodes (4): _AttachmentBadge, attachmentsByCodeProvider, attachmentsCountByCodeProvider, _showAttachmentsDialog

## Knowledge Gaps
- **1886 isolated node(s):** `dragDevices`, `_subscription`, `dispose`, `HelpTexts`, `all` (+1881 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `PdfStringSanitization` connect `admin_checklist_page.dart` to `report_template.dart`?**
  _High betweenness centrality (0.019) - this node is a cross-community bridge._
- **Why does `AppDatabase` connect `audits_repository.dart` to `app_database.dart`, `sync_controller.dart`, `alerts_provider.dart`, `report_service.dart`, `../../../core/storage/db_providers.dart`, `admin_repository.dart`, `inspector_action_service.dart`?**
  _High betweenness centrality (0.014) - this node is a cross-community bridge._
- **Why does `Visit` connect `DataClass` to `app_database.dart`, `visit_workspace_page.dart`, `visits_page.dart`, `admin_dashboard_page.dart`?**
  _High betweenness centrality (0.012) - this node is a cross-community bridge._
- **What connects `dragDevices`, `_subscription`, `dispose` to the rest of the system?**
  _1886 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `app_database.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.0027063599458728013 - nodes in this community are weakly interconnected._
- **Should `visit_workspace_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.011834319526627219 - nodes in this community are weakly interconnected._
- **Should `attachments_page.dart` be split into smaller, more focused modules?**
  _Cohesion score 0.024390243902439025 - nodes in this community are weakly interconnected._