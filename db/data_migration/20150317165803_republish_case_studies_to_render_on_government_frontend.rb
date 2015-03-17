DataHygiene::PublishingApiRepublisher.new(CaseStudy.where(:state => Edition::PUBLICLY_VISIBLE_STATES)).perform
