<?php                                                                                                                                                                                                                                         
/**                                                                                                                                                                                                                                           
 *                                                                                                                                                                                                                                            
 * SugarCRM Community Edition is a customer relationship management program developed by                                                                                                                                                      
 * SugarCRM, Inc. Copyright (C) 2004-2013 SugarCRM Inc.                                                                                                                                                                                       
 *                                                                                                                                                                                                                                            
 * SuiteCRM is an extension to SugarCRM Community Edition developed by SalesAgility Ltd.                                                                                                                                                      
 * Copyright (C) 2011 - 2019 SalesAgility Ltd.                                                                                                                                                                                                
 *                                                                                                                                                                                                                                            
 * This program is free software; you can redistribute it and/or modify it under                                                                                                                                                              
 * the terms of the GNU Affero General Public License version 3 as published by the                                                                                                                                                           
 * Free Software Foundation with the addition of the following permission added                                                                                                                                                               
 * to Section 15 as permitted in Section 7(a): FOR ANY PART OF THE COVERED WORK                                                                                                                                                               
 * IN WHICH THE COPYRIGHT IS OWNED BY SUGARCRM, SUGARCRM DISCLAIMS THE WARRANTY                                                                                                                                                               
 * OF NON INFRINGEMENT OF THIRD PARTY RIGHTS.                                                                                                                                                                                                 
 *                                                                                                                                                                                                                                            
 * This program is distributed in the hope that it will be useful, but WITHOUT                                                                                                                                                                
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS                                                                                                                                                              
 * FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more                                                                                                                                                               
 * details.                                                                                                                                                                                                                                   
 *                                                                                                                                                                                                                                            
 * You should have received a copy of the GNU Affero General Public License along with                                                                                                                                                        
 * this program; if not, see http://www.gnu.org/licenses or write to the Free                                                                                                                                                                 
 * Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA                                                                                                                                                                     
 * 02110-1301 USA.   
 *     
 * You can contact SugarCRM, Inc. headquarters at 10050 North Wolfe Road,                                              
 * SW2-130, Cupertino, CA 95014, USA. or at email address contact@sugarcrm.com.
 *                                                                                                                     
 * The interactive user interfaces in modified source and object code versions
 * of this program must display Appropriate Legal Notices, as required under
 * Section 5 of the GNU Affero General Public License version 3.
 *                                                         
 * In accordance with Section 7(b) of the GNU Affero General Public License version 3,
 * these Appropriate Legal Notices must retain the display of the "Powered by
 * SugarCRM" logo and "Supercharged by SuiteCRM" logo. If the display of the logos is not
 * reasonably feasible for technical reasons, the Appropriate Legal Notices must
 * display the words "Powered by SugarCRM" and "Supercharged by SuiteCRM".
 */                                                 

namespace SuiteCRM\Robo\Plugin\Commands;                                                                                                                                                                                                      

use DBManager;                                                                                                                                                                                                                                
use Robo\Tasks;                                                                                                                                                                                                                               
use SuiteCRM\Robo\Traits\RoboTrait;                                                                                                                                                                                                           
use SuiteCRM\Robo\Traits\CliRunnerTrait;                                                                                                                                                                                                      
use Api\V8\BeanDecorator\BeanManager;                                                                                                                                                                                                         
use DBManagerFactory;                                                                                                                                                                                                                         
use User;                                                                                                                                                                                                                                     

class CreateUserCommands extends Tasks                                                                                                                                                                                                        
{                                                                                                                                                                                                                                             
    use RoboTrait;                                                                                                                                                                                                                            
    use CliRunnerTrait;                                                                                                                                                                                                                       

    /**                                                                                                                                                                                                                                       
     * @var DBManager
     */
    protected $db;                                                                                                     

    /**                                                                                                                
     * @var BeanManager
     */                  
    protected $beanManager;                           

    /**   
     * @var array
     */                      
    protected static $beanAliases = [ 
        User::class => 'Users',
        OAuth2Clients::class => 'OAuth2Clients',    
    ];                 

    /**
     * CreateUserCommands constructor    
     */                                   
    public function __construct()        
    {                                
        $this->bootstrap();                
        $this->db = DBManagerFactory::getInstance();
        $this->beanManager = new BeanManager($this->db, static::$beanAliases);
    }                     

    /**
     * Creates a SuiteCRM user                          
     * @param string $username
     * @param string $password
     * @param string $is_admin
     * @return void
     */
    public function createUser($username, $password, $is_admin)
    {
        $count = $this->getNameCount($username, 'users', 'user_name');

        if ($count > 1) {
            $this->io()->title('User Already Exists');
            return;
        };

        global $current_user;
        $current_user->is_admin = '1';

        $userBean = $this->beanManager->newBeanSafe(
            User::class
        );

        $userBean->user_name = $username;
        $userBean->first_name = $username;
        $userBean->last_name = $username;
        $userBean->status = 'Active';
        $userBean->title = "Administrator";
        $userBean->employee_status = 'Active';
        $userBean->is_admin = filter_var($is_admin, FILTER_VALIDATE_BOOLEAN);
        $userBean->save();
        $userBean->setNewPassword($password, 1);

        $this->io()->title('Successfully Created User');
    }

    /**
     * Returns the number of duplicate name records from a table
     * @param string $name
     * @param string $table
     * @param string $row
     * @return int
     */
    private function getNameCount($name, $table, $row)
    {
        $nameQuoted = $this->db->quoted($name);

        $query = <<<SQL
SELECT
    count(`id`) AS `count`
FROM
    `$table`
WHERE
    `$row` LIKE '$nameQuoted %'
SQL;

        $result = $this->db->fetchOne($query);

        $count = $result
            ? (int)$result['count']
            : 0;

        $count++;

        return $count;
    }
}
