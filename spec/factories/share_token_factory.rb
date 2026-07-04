FactoryBot.define do
  factory :share_token do
    user
    snapshot_data do
      {
        accuracy_rate: 80,
        total_study_days: 10,
        mastery_rate: 60,
        total_answers: 100,
        daily_stats: { "2026-07-01" => 3, "2026-07-02" => 5 },
        mastery_history: [ { week: "2026-W26", rate: 50 }, { week: "2026-W27", rate: 60 } ]
      }
    end
  end
end
