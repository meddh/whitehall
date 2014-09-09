require 'test_helper'

class Admin::TaggableContentHelperTest < ActionView::TestCase

  test '#taggable_topics_container returns an array of name/ID pairs for all Topics' do
    topic_b = create(:topic, name: 'Topic B')
    topic_a = create(:topic, name: 'Topic A')
    topic_c = create(:topic, name: 'Topic C')

    assert_equal [
      ['Topic A', topic_a.id],
      ['Topic B', topic_b.id],
      ['Topic C', topic_c.id],
    ], taggable_topics_container
  end

  test '#taggable_topical_events_container returns an array of name/ID pairs for all TopicalEvents' do
    event_a = create(:topical_event, name: 'Event A')
    event_c = create(:topical_event, name: 'Event C')
    event_b = create(:topical_event, name: 'Event B')

    assert_equal [
      ['Event A', event_a.id],
      ['Event B', event_b.id],
      ['Event C', event_c.id],
    ], taggable_topical_events_container
  end
end
