import { type Request, type Response } from 'express'
import * as models from '../models/index'

// Archivo de prueba para verificar que el pipeline bloquea una inyección SQL nueva.
export function consultaPrueba () {
  return (req: Request, res: Response) => {
    models.sequelize.query(`SELECT * FROM Users WHERE email = '${req.query.email}'`)
      .then((resultado: any) => res.json(resultado))
  }
}
