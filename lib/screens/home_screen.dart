import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme_controller.dart';
import '../utils/auth_controller.dart';
import '../models/appointment.dart';
import '../models/patient.dart';
import '../utils/database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper();
  bool _isLoading = true;
  List<Appointment> _todayAppointments = [];
  Map<String, Patient> _patients = {};
  Map<String, int> _stats = {
    'patients': 0,
    'todayVisits': 0,
    'todayAppointments': 0
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load quick stats
      final stats = await _db.getQuickStats();

      // Load today's appointments
      final appointments = await _db.getTodayAppointments();

      // Load patient details for each appointment
      final Map<String, Patient> patients = {};
      for (var appointment in appointments) {
        if (!patients.containsKey(appointment.patientId)) {
          final patient = await _db.getPatient(appointment.patientId);
          if (patient != null) {
            patients[appointment.patientId] = patient;
          }
        }
      }

      if (mounted) {
        setState(() {
          _stats = stats;
          _todayAppointments = appointments;
          _patients = patients;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = Provider.of<ThemeController>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MedDex',
          style: TextStyle(fontSize: 18),
        ),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, size: 22),
            tooltip: 'Search patients',
            onPressed: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings, size: 22),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 22,
            ),
            tooltip: 'Toggle theme',
            onPressed: () {
              themeController.setThemeMode(
                isDarkMode ? ThemeMode.light : ThemeMode.dark,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: _buildNavigationDrawer(context),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with welcome message
                _buildWelcomeHeader(context),

                // Quick Stats
                _buildQuickStats(context),

                // Main Action Cards
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Quick Actions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Main action cards in a grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LayoutBuilder(builder: (context, constraints) {
                    // Calculate ideal number of columns based on screen width
                    final double minCardWidth = isSmallScreen ? 65 : 75;
                    final int crossAxisCount =
                        (constraints.maxWidth / minCardWidth)
                            .floor()
                            .clamp(2, 4);
                    final childAspectRatio = isSmallScreen ? 1.0 : 1.1;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: isSmallScreen ? 6 : 8,
                      crossAxisSpacing: isSmallScreen ? 6 : 8,
                      childAspectRatio: childAspectRatio,
                      children: [
                        _buildGridActionCard(
                          context,
                          Icons.people,
                          'Patients',
                          Colors.blue,
                          () => Navigator.pushNamed(context, '/patients'),
                        ),
                        _buildGridActionCard(
                          context,
                          Icons.person_add,
                          'Add Patient',
                          Colors.green,
                          () => Navigator.pushNamed(context, '/patient/add'),
                        ),
                        _buildGridActionCard(
                          context,
                          Icons.add_box,
                          'Add Visit',
                          Colors.teal,
                          () => Navigator.pushNamed(context, '/visit/add'),
                        ),
                        _buildGridActionCard(
                          context,
                          Icons.calendar_today,
                          'Appointments',
                          Colors.orange,
                          () => Navigator.pushNamed(context, '/appointments'),
                        ),
                      ],
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Today's Appointments
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: isSmallScreen ? 8 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Today\'s Appointments',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/appointments'),
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: const Text(
                              'View All',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildAppointmentList(context),
                    ],
                  ),
                ),

                // Recent Activity
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: isSmallScreen ? 8 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRecentActivity(context),
                    ],
                  ),
                ),
                // Add bottom padding to avoid FAB overlap
                SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/patient/add'),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('New Patient', style: TextStyle(fontSize: 14)),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Patient Management Dashboard',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Stats',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Total Patients',
                  _stats['patients']?.toString() ?? '...',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Today\'s Visits',
                  _stats['todayVisits']?.toString() ?? '...',
                  Icons.calendar_today,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Today\'s Appointments',
                  _stats['todayAppointments']?.toString() ?? '...',
                  Icons.access_time,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    Widget cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: isSmallScreen ? 18 : 20,
          color: color,
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: cardContent,
    );
  }

  Widget _buildGridActionCard(BuildContext context, IconData icon, String label,
      Color color, VoidCallback onTap) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 360;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.05),
              blurRadius: 2,
              spreadRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isSmallScreen ? 22 : 24,
              color: color,
            ),
            SizedBox(height: isSmallScreen ? 4 : 5),
            Text(
              label,
              style: TextStyle(
                fontSize: isSmallScreen ? 11 : 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentList(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_todayAppointments.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No appointments today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Schedule appointments during patient visits',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _todayAppointments.length,
      itemBuilder: (context, index) {
        final appointment = _todayAppointments[index];
        final patient = _patients[appointment.patientId];
        if (patient == null) return const SizedBox.shrink();

        final now = DateTime.now();
        final appointmentTime = appointment.appointmentDate;
        final isNow = now.difference(appointmentTime).inMinutes.abs() <= 30;
        final isPassed = appointmentTime.isBefore(now);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(
                context,
                '/patient',
                arguments: patient,
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                if (appointment.isFollowUp)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 16,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Follow-up Visit',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            child: Text(
                              patient.name.substring(0, 2).toUpperCase(),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  patient.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 14,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${appointmentTime.hour.toString().padLeft(2, '0')}:${appointmentTime.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(
                                      Icons.phone,
                                      size: 14,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      patient.contactNumber,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                if (appointment.purpose.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    appointment.purpose,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isNow
                                  ? Colors.green.withOpacity(0.1)
                                  : isPassed
                                      ? Colors.orange.withOpacity(0.1)
                                      : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isNow
                                    ? Colors.green.withOpacity(0.5)
                                    : isPassed
                                        ? Colors.orange.withOpacity(0.5)
                                        : Colors.blue.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              isNow
                                  ? 'Now'
                                  : isPassed
                                      ? 'Passed'
                                      : 'Upcoming',
                              style: TextStyle(
                                color: isNow
                                    ? Colors.green
                                    : isPassed
                                        ? Colors.orange
                                        : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (appointment.notes?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.notes,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  appointment.notes!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final newStatus =
                                  appointment.status == 'completed'
                                      ? 'scheduled'
                                      : 'completed';
                              await _db.updateAppointmentStatus(
                                appointment.id,
                                newStatus,
                              );
                              _loadData();
                            },
                            icon: Icon(
                              appointment.status == 'completed'
                                  ? Icons.check_circle
                                  : Icons.check_circle_outline,
                              size: 18,
                              color: appointment.status == 'completed'
                                  ? Colors.green
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.7),
                            ),
                            label: Text(
                              appointment.status == 'completed'
                                  ? 'Completed'
                                  : 'Mark as Complete',
                              style: TextStyle(
                                fontSize: 12,
                                color: appointment.status == 'completed'
                                    ? Colors.green
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.7),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivity(BuildContext context) {
    final activities = [
      {
        'action': 'Added new patient',
        'subject': 'Sarah Johnson',
        'time': '2 hours ago',
        'icon': Icons.person_add,
        'color': Colors.green,
      },
      {
        'action': 'Updated prescription',
        'subject': 'Robert Brown',
        'time': '4 hours ago',
        'icon': Icons.edit,
        'color': Colors.orange,
      },
      {
        'action': 'Completed visit',
        'subject': 'Emily Davis',
        'time': 'Yesterday',
        'icon': Icons.check_circle,
        'color': Colors.blue,
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: (activity['color'] as Color).withOpacity(0.2),
            child: Icon(
              activity['icon'] as IconData,
              color: activity['color'] as Color,
              size: 20,
            ),
          ),
          title: Text(
            activity['action'] as String,
            style: const TextStyle(fontSize: 16),
          ),
          subtitle: Text(
            activity['subject'] as String,
            style: const TextStyle(fontSize: 14),
          ),
          trailing: Text(
            activity['time'] as String,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authController = Provider.of<AuthController>(context, listen: false);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Dr. John Smith',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'General Physician',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimary
                        .withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, size: 22),
            title: const Text('Dashboard', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people, size: 22),
            title: const Text('Patients', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/patients');
            },
          ),
          ListTile(
            leading: const Icon(Icons.calendar_today, size: 22),
            title: const Text('Appointments', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/appointments');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings, size: 22),
            title: const Text('Settings', style: TextStyle(fontSize: 16)),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: Icon(
              isDarkMode ? Icons.light_mode : Icons.dark_mode,
              size: 22,
            ),
            title: const Text('Toggle Theme', style: TextStyle(fontSize: 16)),
            onTap: () {
              final themeController =
                  Provider.of<ThemeController>(context, listen: false);
              themeController.setThemeMode(
                isDarkMode ? ThemeMode.light : ThemeMode.dark,
              );
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, size: 22),
            title: const Text('Logout', style: TextStyle(fontSize: 16)),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text(
                      'Confirm Logout',
                      style: const TextStyle(fontSize: 18),
                    ),
                    content: Text(
                      'Are you sure you want to logout?',
                      style: const TextStyle(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text(
                          'Cancel',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          authController.logout();
                          Navigator.of(context).pop();
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: const Text(
                          'Logout',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
