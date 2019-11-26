Feature: Variant Branching
  In order to avoid redundancy
  As a feature writer
  I must be able to use placeholders on Feature Backgrounds

  Background:
    Given a file named "features/bootstrap/FeatureContext.php" with:
      """
      <?php
      use Behat\Behat\Context\Context;

      class FeatureContext implements Context
      {
        /**
         * @Then /^the ice cream truck delivers "(?P<flavor>[^"]*)" ice cream to "(?P<restaurant>[^"]*)"/
         */
        public function echoSuccessfulShipment($flavor, $restaurant) {
            echo "$restaurant got their $flavor ice cream shipment!";
        }

        /**
         * @Given /^there are ice cream deliveries to be made on "(?P<neighborhood>[^"]*)"$/
         */
        public function echoNeighborhoodDeliveries($neighborhood) {
            echo "Let's get some ice creams to $neighborhood!";
        }
      }
      """
    And a file named "behat.yml" with:
      """
      default:
          extensions:
              Ciandt\Behat\PlaceholdersExtension:
                  variant_tags: ~
                  config_tags:
                      ice_cream: '%paths.base%/features/ice_cream.yml'
      """
    And a file named "features/ice_cream.yml" with:
      """
      default:
        placeholders:
          neighborhood:
            $default: Manhattan
            $hells_kitchen: Hell's Kitchen
          restaurant:
            $default: Starbugs
            $hells_kitchen: Burguer Queen
          flavor:
            $default: vanilla
            $hells_kitchen: pistachio

      """
    And a file named "features/environment.feature" with:
      """
      Feature: Ice cream delivery

      @ice_cream
      Scenario: Deliver ice cream shipment to restaurant
          Given there are ice cream deliveries to be made on "${neighborhood}"
          Then the ice cream truck delivers "${flavor}" ice cream to "${restaurant}"
      """


    Scenario: Default environment placeholders


        When I run "behat features/environment.feature"
        Then it should pass with:
          """
            @ice_cream
            Scenario: Deliver ice cream shipment to restaurant                           # features/environment.feature:4
              Given there are ice cream deliveries to be made on "${neighborhood}"       # FeatureContext::echoNeighborhoodDeliveries()
                │ Let's get some ice creams to Manhattan!
              Then the ice cream truck delivers "${flavor}" ice cream to "${restaurant}" # FeatureContext::echoSuccessfulShipment()
                │ Starbugs got their vanilla ice cream shipment!

          1 scenario (1 passed)
          2 steps (2 passed)
          """

    Scenario: Specific environment placeholders


        When I run "behat --environment hells_kitchen features/environment.feature"
        Then it should pass with:
          """
            @ice_cream
            Scenario: Deliver ice cream shipment to restaurant                           # features/environment.feature:4
              Given there are ice cream deliveries to be made on "${neighborhood}"       # FeatureContext::echoNeighborhoodDeliveries()
                │ Let's get some ice creams to Hell's Kitchen!
              Then the ice cream truck delivers "${flavor}" ice cream to "${restaurant}" # FeatureContext::echoSuccessfulShipment()
                │ Burguer Queen got their pistachio ice cream shipment!

          1 scenario (1 passed)
          2 steps (2 passed)
          """

