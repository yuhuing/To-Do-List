class Task {
  String title;
  String details;
  bool isDone;
  DateTime dueDate; 

  Task({
    required this.title,
    required this.details,
    required this.dueDate, 
    this.isDone = false,
  });
}
