Feature: Placeholders on special arguments
  In order to avoid redundancy
  As a feature writer
  I must be able to use placeholders on TableNodes and PyStrings

  Background:
    Given a file named "features/bootstrap/FeatureContext.php" with:
      """
      <?php
      use Behat\Behat\Context\Context;

      class FeatureContext implements Context
      {
        /**
         * @Given /^the ice cream truck has "(?P<flavor>[^"]*)" ice cream$/
         */
        public function echoFlavor($flavor) {
            echo "It sells $flavor ice cream";
        }

        /**
         * @Given /^the ice cream truck received the "(?P<flavor>[^"]*)" ice cream shipment$/
         */
        public function echoShipmentFlavor($flavor) {
            echo "There's $flavor ice cream available!";
        }

        /**
         * @Given /^the "(?P<company>[^"]*)" ice cream truck is on duty today$/
         */
        public function echoCompanyTruck($company) {
            echo "Let's get some $company ice creams out there!";
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
          company_name: CI&T Gelatos
      """
      

    Scenario: Background with variant branching
        Given a file named "features/background.feature" with:
          """
          Feature: Ice cream trucks

          Background: The truck received the ice cream shipment
            Given the ice cream truck received the "${flavor}" ice cream shipment
          
          @ice_cream @vanilla @chocolate @pistachio
          Scenario: Sell the available ice cream flavors
              Given the ice cream truck has "${flavor}" ice cream
          """

        When I run "behat features/background.feature"
        Then it should pass with:
          """
            Background: The truck received the ice cream shipment                   # features/background.feature:3
              Given the ice cream truck received the "${flavor}" ice cream shipment # FeatureContext::echoShipmentFlavor()
                │ There's vanilla ice cream available!

            @ice_cream @vanilla
            Scenario: Sell the available ice cream flavors        # features/background.feature:7
              Given the ice cream truck has "${flavor}" ice cream # FeatureContext::echoFlavor()
                │ It sells vanilla ice cream

            @ice_cream @chocolate
            Scenario: Sell the available ice cream flavors        # features/background.feature:7
              Given the ice cream truck received the "${flavor}" ice cream shipment # FeatureContext::echoShipmentFlavor()
                │ There's chocolate ice cream available!
              Given the ice cream truck has "${flavor}" ice cream # FeatureContext::echoFlavor()
                │ It sells chocolate ice cream

            @ice_cream @pistachio
            Scenario: Sell the available ice cream flavors        # features/background.feature:7
              Given the ice cream truck received the "${flavor}" ice cream shipment # FeatureContext::echoShipmentFlavor()
                │ There's pistachio ice cream available!
              Given the ice cream truck has "${flavor}" ice cream # FeatureContext::echoFlavor()
                │ It sells pistachio ice cream

          3 scenarios (3 passed)
          6 steps (6 passed)
          """