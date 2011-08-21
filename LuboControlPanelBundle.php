<?php

namespace Lubo\ControlPanelBundle;

use Symfony\Component\HttpKernel\Bundle\Bundle;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Lubo\ControlPanelBundle\DependencyInjection\LuboControlPanelExtension;

class LuboControlPanelBundle extends Bundle
{
    public function __construct()
    {
        $this->extension = new LuboControlPanelExtension();
    }

    public function build(ContainerBuilder $container)
    {
        parent::build($container);
    }
}
