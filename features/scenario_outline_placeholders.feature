@tags
Feature: Scenario Outline Placeholders
  In order to avoid redundancy
  As a feature writer
  I need to use placeholders on scenario outlines

  Background:
    Given a file named "features/bootstrap/FeatureContext.php" with:
      """
      <?php
      use Behat\Behat\Context\Context;

      class FeatureContext implements Context
      {
        /**
         * @Given /^the ice cream truck sells a "(?P<flavor>[^"]*)" ice cream to "(?P<client>[^"]*)"$/
         */
        public function sellIceCream($flavor, $client) {
            echo "It sells a $flavor ice cream to $client";
        }
      }
      """
    And a file named "behat.yml" with:
      """
      default:
          extensions:
              Ciandt\Behat\PlaceholdersExtension:
                  variant_tags:
                      - vanilla
                      - chocolate
                      - pistachio
                  config_tags:
                      ice_cream: '%paths.base%/features/ice_cream.yml'
      """
    And a file named "features/ice_cream.yml" with:
      """
      default:
        placeholders:
          flavor:
            $default:
              $vanilla: vanilla
              $chocolate: chocolate
              $pistachio: pistachio
      """

    @test
    Scenario: Scenario Outline
        Given a file named "features/scenario_outline.feature" with:
          """
          Feature: Scenario Outline with placeholders
            @ice_cream @vanilla @chocolate
            Scenario Outline: Offer a single ice cream flavor
              Given the ice cream truck sells a "${flavor}" ice cream to "<client>"
            Scenarios:
            | client |
            | Luke Cage |
            | Peter Parker |
          """

        When I run "behat features/scenario_outline.feature"
        Then it should pass with:
          """
            @ice_cream @vanilla
            Scenario Outline: Offer a single ice cream flavor                       # features/scenario_outline.feature:3
              Given the ice cream truck sells a "${flavor}" ice cream to "<client>" # FeatureContext::sellIceCream()

              Scenarios:
                | client       |
                | Luke Cage    |
                  │ It sells a vanilla ice cream to Luke Cage
                | Peter Parker |
                  │ It sells a vanilla ice cream to Peter Parker

            @ice_cream @chocolate
            Scenario Outline: Offer a single ice cream flavor                       # features/scenario_outline.feature:3
              Given the ice cream truck sells a "${flavor}" ice cream to "<client>" # FeatureContext::sellIceCream()

              Scenarios:
                | client       |
                | Luke Cage    |
                  │ It sells a chocolate ice cream to Luke Cage
                | Peter Parker |
                  │ It sells a chocolate ice cream to Peter Parker

          4 scenarios (4 passed)
          4 steps (4 passed)
          """

