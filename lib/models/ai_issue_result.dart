class AiIssueResult {
  const AiIssueResult({
    this.issueName,
    this.explanation,
    this.possibleCauses,
    this.fixSteps,
    this.estimatedCost,
    this.urgency,
  });

  final String? issueName;
  final String? explanation;
  final String? possibleCauses;
  final String? fixSteps;
  final String? estimatedCost;
  final String? urgency;

  Map<String, dynamic> toJson() => {
        'issue_name': issueName,
        'explanation': explanation,
        'possible_causes': possibleCauses,
        'fix_steps': fixSteps,
        'estimated_cost': estimatedCost,
        'urgency': urgency,
      };

  factory AiIssueResult.fromJson(Map<String, dynamic> json) {
    return AiIssueResult(
      issueName: json['issue_name'] as String? ?? json['Issue Name'] as String?,
      explanation:
          json['explanation'] as String? ?? json['Simple Explanation'] as String?,
      possibleCauses: json['possible_causes'] as String? ??
          json['Possible Causes'] as String?,
      fixSteps: json['fix_steps'] as String? ??
          json['Step-by-step Fix'] as String?,
      estimatedCost: json['estimated_cost'] as String? ??
          json['Estimated Cost'] as String?,
      urgency: json['urgency'] as String? ?? json['Urgency Level'] as String?,
    );
  }

  factory AiIssueResult.fromRawText(String text) {
    return AiIssueResult(
      explanation: text,
      issueName: 'Analysis',
    );
  }
}
