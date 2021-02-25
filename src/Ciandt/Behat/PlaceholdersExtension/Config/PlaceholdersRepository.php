<?php
namespace Ciandt\Behat\PlaceholdersExtension\Config;

use Symfony\Component\Yaml\Yaml;
use Ciandt\Behat\PlaceholdersExtension\Utils\PlaceholderUtils;
use Ciandt\Behat\PlaceholdersExtension\PlaceholderContainer\PlaceholderContainer;
use Ciandt\Behat\PlaceholdersExtension\Exception\MissingSectionException;
use Ciandt\Behat\PlaceholdersExtension\Exception\UndefinedPlaceholderException;
use Exception;

/**
 * Description of ConfigsRepository
 *
 * @author bwowk
 */
class PlaceholdersRepository
{
    const PLACEHOLDER_REGEX = '/\${(?P<placeholder>[a-zA-Z0-9_-]+)}/';
    
    private $configs;
    
    private $beforeScenarioSubscriber;
    
    private $runtimePlaceholders = array();

    /**
     * @var string
     */
    private $environment;

    public function __construct($configs_mapping, $beforeScenarioSubscriber)
    {
        $this->configs = $this->loadConfigFiles($configs_mapping);
        $this->beforeScenarioSubscriber = $beforeScenarioSubscriber;
    }

    /**
     *
     * @return string[]
     * @todo read configs and also bring alternative @config:section tags
     */
    public function getTags()
    {
        return array_keys($this->configs);
    }

    /**
     * reads the YAML placeholder definitions and returns an associative array
     *
     * @param type $config_files
     * @todo use %paths.base% value
     * @return array
     */
    private function loadConfigFiles($configs_mapping)
    {
        $placeholder_maps = array();

        foreach ($configs_mapping as $tag => $file_path) {
            if (!is_array($file_path)) {
                $file_path = [$file_path];
            }
            $placeholder_maps[$tag]['config'] = [];

            foreach ($file_path as $path) {
                $placeholder_maps[$tag]['config'] = array_replace_recursive(
                    $placeholder_maps[$tag]['config'],
                    Yaml::parse(file_get_contents($path))
                );
            }

            $placeholder_maps[$tag]['path'] = implode(',', $file_path);
        }

        return $placeholder_maps;
    }

    private function getConfig($key)
    {
        if (key_exists($key, $this->configs)) {
            return $this->configs[$key]['config'];
        }
        return null;
    }

    private function getFilePath($key)
    {
         if (key_exists($key, $this->configs)) {
            return $this->configs[$key]['path'];
        }
        return null;
    }
       
    public function getEnvironment()
    {
        return $this->environment;
    }

    public function setEnvironment($environment)
    {
        $this->environment = $environment;
    }
    
    private function getScenarioTags(){
        return $this->beforeScenarioSubscriber->getScenarioTags();
    }

    private function replaceRecursively($placeholder, $replaced = array())
    {
        // if the current placeholder was already replaced before, this is a cyclic dependecy
        if (in_array($placeholder, $replaced)) {
            $tree = implode('>', $replaced);
            throw new Exception("Cyclic placeholder dependecy detected. Trying to replace $placeholder again when already replaced: $tree");
        }

        $tags = $this->getScenarioTags();

        //@todo abort if there's no config tag
        $configTag = PlaceholderUtils::getConfigTag($tags);
        $configKey = PlaceholderUtils::getConfigKey($configTag);

        $variantTags = PlaceholderUtils::filterVariantTags($tags, false);
        $variant = end($variantTags);
        $environment = $this->getEnvironment();

        $keys = array('$' . $variant, '$' . $environment, $placeholder);

        // First try to find it in the runtime placeholders
        $replacement = $this->recursiveReplacementSearch($keys, $this->runtimePlaceholders);


        // Then look in the placeholder files
        if ($replacement === null && $configTag !== false ) {
            $section = PlaceholderUtils::getSectionKey($configTag);
            $placeholders = $this->getSectionPlaceholders($configKey, $section);
            $replacement = $this->recursiveReplacementSearch($keys, $placeholders);
        }

        if ($replacement === null && $configTag !== false){
            $configPath = $this->getFilePath($configKey);
            $treePosition = "$configPath>$section>placeholders";
            throw new UndefinedPlaceholderException("No $placeholder replacement was defined on runtime or on $treePosition>$placeholder for variant $variant and environment $environment");
        } elseif ($replacement === null && $configTag === false) {
            throw new UndefinedPlaceholderException("No $placeholder replacement was defined on runtime, and this scenario is not linked with any replacements file");
        }

        //if the replaced string doesn't have placeholders itself, return it right away
        if (preg_match_all(self::PLACEHOLDER_REGEX, $replacement, $matches, PREG_SET_ORDER) == 0) {
            return $replacement;
        }

        //if it does have, replace them before returning
        foreach ($matches as $match) {
            $replaced[] = $placeholder;
            $replacement = str_replace('${' . $match['placeholder'] . '}', $this->replaceRecursively($match['placeholder'], $replaced), $replacement);
        }
        return $replacement;
    }

    public function getReplacement($placeholder)
    {
        return $this->replaceRecursively($placeholder);
    }
    
    private function recursiveReplacementSearch($keys, $values)
    {
        if (empty($keys) || is_scalar($values)) {
            return $values;
        }
        $key = array_pop($keys);
        if (key_exists($key, $values)) {
            $specificValue = $this->recursiveReplacementSearch($keys, $values[$key]);
            if ($specificValue) {
                return $specificValue;
            }
        } if (key_exists('$default', $values)) {
            $defaultValue = $this->recursiveReplacementSearch($keys, $values['$default']);
            if ($defaultValue) {
                return $defaultValue;
            }
        }
        
        return null;
    }
    
    private function getSectionPlaceholders($configKey, $section)
    {
        $config = $this->getConfig($configKey);
        if (!isset($config) || !key_exists($section, $config)) {
            throw new MissingSectionException(
                $configKey,
                $this->getFilePath($configKey),
                $section
            );
        }
        return $config[$section]['placeholders'];
    }
    
    public function setReplacement($key, $value, $environment = '$default', $variant = '$default')
    {
        if (!isset($this->runtimePlaceholders[$key])) {
            $this->runtimePlaceholders[$key] = array();
        }
        if (!isset($this->runtimePlaceholders[$key][$environment])) {
            $this->runtimePlaceholders[$key][$environment] = array();
        }
        $this->runtimePlaceholders[$key][$environment][$variant] = $value;
    }

}
