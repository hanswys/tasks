# frozen_string_literal: true

FactoryBot.define do
  factory :category do
    name { Faker::Company.department }
    color { Faker::Color.hex_color }
  end

  factory :tag do
    name { Faker::Lorem.word }
    color { Faker::Color.hex_color }
  end

  factory :task do
    title { Faker::Lorem.sentence(word_count: 5) }
    description { Faker::Lorem.paragraph }
    status { :pending }
    priority { :medium }
    due_date { 7.days.from_now }
    position { 1 }
    estimated_minutes { 60 }
    category { nil }
    parent { nil }

    trait :completed do
      status { :completed }
    end

    trait :in_progress do
      status { :in_progress }
    end

    trait :pending do
      status { :pending }
    end

    trait :archived do
      status { :archived }
    end

    trait :with_category do
      category { create(:category) }
    end

    trait :with_tags do
      after(:create) do |task|
        create_list(:tag, 2, tasks: [task])
      end
    end

    trait :high_priority do
      priority { :high }
    end

    trait :urgent do
      priority { :urgent }
    end

    trait :overdue do
      due_date { 1.day.ago }
      status { :pending }
    end

    trait :overdue_completed do
      due_date { 1.day.ago }
      status { :completed }
    end
  end

  factory :task_tag do
    task
    tag
  end
end
