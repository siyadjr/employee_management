class Employee {
  final String id;
  final String name;
  final String department;
  final double casualLeaveBalance;
  final double sickLeaveBalance;

  Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.casualLeaveBalance,
    required this.sickLeaveBalance,
  });

  double get totalLeaveBalance => casualLeaveBalance + sickLeaveBalance;

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] as String,
      name: json['name'] as String,
      department: json['department'] as String,
      casualLeaveBalance: (json['casualLeaveBalance'] as num).toDouble(),
      sickLeaveBalance: (json['sickLeaveBalance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'casualLeaveBalance': casualLeaveBalance,
      'sickLeaveBalance': sickLeaveBalance,
    };
  }

  // Preconfigured demo employee
  static Employee defaultEmployee() {
    return Employee(
      id: 'EMP-1042',
      name: 'Alex Mercer',
      department: 'Core Platform Engineering',
      casualLeaveBalance: 12.0,
      sickLeaveBalance: 6.0,
    );
  }
}
