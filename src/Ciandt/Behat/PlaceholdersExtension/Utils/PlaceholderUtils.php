<?php

namespace Ciandt\Behat\PlaceholdersExtension\Utils;

use Ciandt\Behat\PlaceholdersExtension\Exception\RedundantConfigTagException;

/**
 * Filters an array of tags, excluding or including only the variant tags
 *
 * @author bwowk
 */
class PlaceholderUtils
{
    private static $variantTags;
    
    private static $configKeys;

    public static function setVariantTags($variantTags)
    {
        self::$variantTags = $variantTags;
    }
    
    public static function setConfigKeys($configKeys)
    {
        self::$configKeys = $configKeys;
    }
    
    public static  function getSectionKey($tag){
        $tagParts = explode(':', $tag);
        if (count($tagParts) == 2){
            return $tagParts[1];
        } else {
            return 'default';
        }
        
    }
    
    public static function getConfigTag($tags){
        $configTags = self::filterConfigTags($tags,false);
        if (empty($configTags)) {
            return false;
        }
        if (count($configTags) > 1) {
            throw new RedundantConfigTagException($configTags);
        }
        return array_values($configTags)[0];
    }


    public static function getConfigKey($tag){
        return explode(':', $tag)[0];
    }
    
    
    public static function filterVariantTags($tags, $exclude)
    {   
        return array_filter($tags, function ($tag) use ($exclude) {
            return (in_array($tag, self::$variantTags) xor $exclude);
        });
    }
    
    public static function getVariant($tags){
        $variantTags = self::filterVariantTags($tags, false);
        if (count($variantTags) > 1) {
            throw new \RuntimeException("Scenario should only have one variant tag."
                    . " Multiple found: " . implode(', ', $variantTags));
        }
        if (empty($variantTags)){
            return 'default';
        }
        return end($variantTags);
    }


    public static function filterConfigTags($tags, $exclude)
    {
        return array_filter($tags, function ($tag) use ($exclude){
            return (in_array(self::getConfigKey($tag), self::$configKeys) xor $exclude);
        });
    }
}
