Feature: Join a set of videos into a single file
  In order to obtain a single video from a set of video files
  As an operator
  I want to join the video set into a single file

  Scenario: Create a joined video file from a set of valid videos
    Given I have a set of correct video files
    When I create the video joiner job with id "valid_test"
    And the video joiner job has finished
    Then there should be a valid video file
    And it should report all included videos as valid

  Scenario: Create a joined video file from a set of invalid videos
    Given I have a set of invalid videos
    When I create the video joiner job with id "invalid_test"
    And the video joiner job has finished
    Then it should report that a video from the set is invalid
    And there should be a valid video file

  Scenario: Create a joined video file with a duplicated id
    Given I have a set of correct video files
    When I create the video joiner job with id "duplicated_test"
    And I create the video joiner job with id "duplicated_test"
    Then it should report that the job creation was unsucessful
