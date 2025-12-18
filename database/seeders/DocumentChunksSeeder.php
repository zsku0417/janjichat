<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class DocumentChunksSeeder extends Seeder
{
    /**
     * Seed the document_chunks table from CSV file.
     * 
     * SETUP:
     * 1. mkdir -p database/seeders/data
     * 2. Copy chunks.csv to database/seeders/data/chunks.csv
     * 3. php artisan db:seed --class=DocumentChunksSeeder
     */
    public function run(): void
    {
        $csvPath = database_path('seeders/data/chunks.csv');
        
        if (!file_exists($csvPath)) {
            $this->command->error("CSV file not found: {$csvPath}");
            $this->command->info("Place chunks.csv in database/seeders/data/");
            return;
        }

        $this->command->info('Seeding document_chunks...');
        
        // Optional: clear existing data
        DB::table('document_chunks')->truncate();
        
        $handle = fopen($csvPath, 'r');
        $count = 0;
        
        while (($row = fgetcsv($handle)) !== false) {
            if (empty($row[0]) || !is_numeric($row[0])) {
                continue;
            }
            
            // Decode HTML entities (e.g., &amp; -> &)
            $content = html_entity_decode($row[2], ENT_QUOTES | ENT_HTML5, 'UTF-8');
            
            // Use parameterized query with vector casting
            DB::statement(
                "INSERT INTO document_chunks 
                    (id, document_id, content, chunk_index, created_at, updated_at, embedding, tokens_count) 
                 VALUES 
                    (?, ?, ?, ?, ?, ?, ?::vector, ?)",
                [
                    (int) $row[0],           // id
                    (int) $row[1],           // document_id
                    $content,                 // content
                    (int) $row[3],           // chunk_index
                    $row[4],                  // created_at
                    $row[5],                  // updated_at
                    trim($row[6]),           // embedding (cast to vector in SQL)
                    (int) $row[7],           // tokens_count
                ]
            );
            
            $count++;
        }
        
        fclose($handle);
        
        // Reset auto-increment sequence
        DB::statement("SELECT setval('document_chunks_id_seq', COALESCE((SELECT MAX(id) FROM document_chunks), 1))");
        
        $this->command->info("✓ Seeded {$count} document chunks.");
    }
}