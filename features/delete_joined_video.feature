Feature: Delete a joined video
  In order to discard a joined video from a set of video files
  As an operator
  I want delete the joined video from that set of video files

  Background:
    Given I have a set of correct video files

  Scenario: Delete a video joiner job
    Given I create the video joiner job with id "delete_test"
    When I delete the video joiner job with id "delete_test"
    Then the joiner video job with id "delete_test" should not exist

  Scenario: Delete a unexistent video joiner job
    Given I create the video joiner job with id "delete_unexistent_test"
    When I delete the video joiner job with id "delete_unexistent_test"
    And I delete the video joiner job with id "delete_unexistent_test"
    Then it should report that the job deletion was unsucessful
