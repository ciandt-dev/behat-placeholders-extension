@tags
Feature: Placeholder chaining
  In order to avoid redundancy
  As a feature writer
  I need to use placeholders inside other placeholders

  Background:
    Given a file named "features/bootstrap/FeatureContext.php" with:
      """
      <?php
      use Behat\Behat\Context\Context;

      class FeatureContext implements Context
      {
        /**
         * @Given the ice cream truck sells ":branded_flavor" ice cream
         */
        public function sellIceCream($branded_flavor) {
            echo "It sells $branded_flavor ice cream";
        }
      }
      """
    And a file named "behat.yml" with:
      """
      default:
          extensions:
              Ciandt\Behat\PlaceholdersExtension:
                  config_tags:
                      ice_cream: '%paths.base%/features/ice_cream.yml'
      """

    Scenario: Placeholder Chaining
        Given a file named "features/ice_cream.yml" with:
          """
          default:
            placeholders:
              brand: Icy Gellato
              cookie: "${brand}'s Crispy Cookie"

          """

        And a file named "features/placeholder_chaining.feature" with:
          """
          @ice_cream
          Feature: Placeholder Chaining
            Scenario: Sell a branded ice cream flavor
              Given the ice cream truck sells "${cookie}" ice cream
          """

        When I run "behat features/placeholder_chaining.feature"
        Then it should pass with:
          """
          @ice_cream
          Feature: Placeholder Chaining
          
            Scenario: Sell a branded ice cream flavor               # features/placeholder_chaining.feature:3
              Given the ice cream truck sells "${cookie}" ice cream # FeatureContext::sellIceCream()
                │ It sells Icy Gellato's Crispy Cookie ice cream
          
          1 scenario (1 passed)
          1 step (1 passed)
          """
      
    Scenario: Cyclic dependency
        Given a file named "features/ice_cream.yml" with:
          """
          default:
            placeholders:
              brand: "Icy Gellato ${cookie}"
              cookie: "${brand}'s Crispy Cookie"

          """
        Given a file named "features/placeholder_chaining.feature" with:
          """
          @ice_cream
          Feature: Placeholder Chaining
            Scenario: Sell a branded ice cream flavor
              Given the ice cream truck sells "${cookie}" ice cream
          """

        When I run "behat features/placeholder_chaining.feature"
        Then it should fail with:
          """
          @ice_cream
          Feature: Placeholder Chaining
          
            Scenario: Sell a branded ice cream flavor               # features/placeholder_chaining.feature:3
              Given the ice cream truck sells "${cookie}" ice cream # FeatureContext::sellIceCream()
                %ACyclic placeholder dependecy detected. Trying to replace cookie again when already replaced: cookie>brand
          """

